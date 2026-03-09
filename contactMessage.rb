require 'json'
require 'aws-sdk-dynamodb'
require 'aws-sdk-ses'
require 'securerandom'
require 'time'

def lambda_handler(event:, context:)
  body = JSON.parse(event['body'] || '{}')

  name    = body['name']    || 'Unknown'
  email   = body['email']   || 'Unknown'
  subject = body['subject'] || 'No Subject'
  message = body['message'] || 'No Message'

  # ── Save to DynamoDB ──
  dynamodb = Aws::DynamoDB::Resource.new
  table = dynamodb.table('ContactMessages')

  table.put_item(
    item: {
      'id'        => SecureRandom.uuid,
      'name'      => name,
      'email'     => email,
      'subject'   => subject,
      'message'   => message,
      'timestamp' => Time.now.utc.iso8601
    }
  )

  # ── Send Email via SES ──
  ses = Aws::SES::Client.new(region: 'ap-south-1')

  ses.send_email(
    source: 'nilgeraman0@gmail.com',
    destination: { to_addresses: ['nilgeraman0@gmail.com'] },
    message: {
      subject: { data: "Portfolio Contact: #{subject}" },
      body: {
        text: {
          data: "Name: #{name}\nEmail: #{email}\nSubject: #{subject}\n\nMessage:\n#{message}"
        }
      }
    }
  )

  ses.send_email(
    source: 'nilgeraman0@gmail.com',
    destination: {to_addresses: ['nilgeraman0@gmail.com']},
    message: {
      subject:{data: "Thanks for reaching out, #{name}! 👋"},
      body:{
        text:{
           data: "Hi #{name},\n\nThank you for contacting me!\n\nI have received your message and will get back to you soon.\n\n⚠️ DISCLAIMER:\nThis portfolio website is built purely for PRACTICE purposes as part of my AWS learning journey. It is not a professional or commercial website.\n\nYour submission details:\n- Name: #{name}\n- Subject: #{subject}\n- Message: #{message}\n\nBest regards,\nAman\nAWS Cloud Learner\n\n---\nThis is an automated reply. Please do not respond to this email."
        }
      }
    }
  )


  # Add this right after parsing body
if name == 'Unknown' || email == 'Unknown' || message == 'No Message'
  return {
    statusCode: 400,
    headers: {
      'Content-Type' => 'application/json',
      'Access-Control-Allow-Origin' => '*'
    },
    body: JSON.generate({ error: 'All fields are required' })
  }
end
  {
    statusCode: 200,
    headers: {
      'Content-Type' => 'application/json',
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'POST, OPTIONS',
      'Access-Control-Allow-Headers' => 'Content-Type'
    },
    body: JSON.generate({ message: 'Message sent successfully!' })
  }

rescue => e
  {
    statusCode: 500,
    headers: {
      'Content-Type' => 'application/json',
      'Access-Control-Allow-Origin' => '*'
    },
    body: JSON.generate({ error: e.message })
  }
end
