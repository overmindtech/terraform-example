# Data source for Lambda function zip file (inline code)
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  
  source {
    content = <<-EOF
import json

def lambda_handler(event, context):
    # Log event size to demonstrate payload limit breach
    event_size = len(json.dumps(event))
    print(f"Event size: {event_size} bytes, Records: {len(event.get('Records', []))}")
    
    return {'statusCode': 200, 'body': f'Processed {len(event.get("Records", []))} messages'}
EOF
    filename = "lambda_function.py"
  }
}
