require 'json'
require 'aws-sdk-dynamodb'

def lambda_handler(event:, context:)
  dynamodb = Aws::DynamoDB::Resource.new
  table = dynamodb.table('VisitorCounter')

  http_method = event.dig('requestContext', 'http', 'method') || 'GET'

  if http_method == 'POST'
    response = table.update_item(
      key: { 'id' => 'global' },
      update_expression: 'ADD #count :increment',
      expression_attribute_names: { '#count' => 'count' },
      expression_attribute_values: { ':increment' => 1 },
      return_values: 'UPDATED_NEW'
    )
    count = response.attributes['count'].to_i
  else
    response = table.get_item(key: { 'id' => 'global' })
    count = response.item ? response.item['count'].to_i : 0
  end

  {
    statusCode: 200,
    headers: {
      'Content-Type' => 'application/json',
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers' => 'Content-Type'
    },
    body: JSON.generate({ count: count })
  }
end
