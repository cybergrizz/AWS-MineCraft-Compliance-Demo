import boto3
import json
import os
from datetime import datetime

ssm = boto3.client('ssm', region_name='us-east-1')
s3  = boto3.client('s3',  region_name='us-east-1')
ddb = boto3.resource('dynamodb', region_name='us-east-1')

INSTANCE_ID = os.environ['INSTANCE_ID']
S3_BUCKET   = os.environ['S3_BUCKET']
TABLE_NAME  = os.environ['TABLE_NAME']

def lambda_handler(event, context):

    # Pull webhook from Parameter Store
    webhook = ssm.get_parameter(
        Name='/minecraft-nist/slack-webhook-url',
        WithDecryption=True
    )['Parameter']['Value']

    # Run scanner.sh on the Minecraft EC2 via SSM Run Command
    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName='AWS-RunShellScript',
        Parameters={'commands': ['bash /home/ec2-user/scanner.sh']},
        TimeoutSeconds=300
    )

    command_id = response['Command']['CommandId']

    # Wait for command to complete
    waiter = ssm.get_waiter('command_executed')
    waiter.wait(
        CommandId=command_id,
        InstanceId=INSTANCE_ID,
        WaiterConfig={'Delay': 5, 'MaxAttempts': 60}
    )

    # Get output
    output = ssm.get_command_invocation(
        CommandId=command_id,
        InstanceId=INSTANCE_ID
    )

    scan_output   = output['StandardOutputContent']
    timestamp     = datetime.utcnow().strftime('%Y-%m-%d_%H-%M-%S')
    report_key    = f'scan-reports/scan_{timestamp}.txt'

    # Save report to S3
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=report_key,
        Body=scan_output.encode('utf-8')
    )

    # Parse pass/fail counts
    pass_count = scan_output.count('‚úÖ')
    fail_count = scan_output.count('‚ùå')

    # Look up NIST control mappings for failed checks
    table    = ddb.Table(TABLE_NAME)
    findings = []

    for line in scan_output.splitlines():
        if '‚ùå' in line:
            findings.append(line.strip())

    # Build and send Slack message
    risk_emoji = 'Ì¥¥' if fail_count >= 6 else ('Ìø°' if fail_count >= 1 else 'Ìø¢')
    risk_level = 'High Risk' if fail_count >= 6 else ('Medium Risk' if fail_count >= 1 else 'Low Risk')

    message = (
        f"{risk_emoji} *{risk_level}*\n"
        f"*Instance:* `{INSTANCE_ID}`\n"
        f"*Results:* ‚úÖ {pass_count} Passed, ‚ùå {fail_count} Failed\n"
        f"*Report:* s3://{S3_BUCKET}/{report_key}\n"
        f"Ìµí {timestamp} UTC"
    )

    import urllib.request
    req = urllib.request.Request(
        webhook,
        data=json.dumps({'text': message}).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    urllib.request.urlopen(req)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'passed': pass_count,
            'failed': fail_count,
            'report': report_key
        })
    }
