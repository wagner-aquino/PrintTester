require 'uri'
require 'net/http'
require 'openssl'
require 'json'

def post_boleto(id, cedente, sh, token_sh, tipo_impressao)
  url_post = URI("https://plugboleto.com.br/api/v1/boletos/impressao/lote")
  http = Net::HTTP.new(url_post.host, url_post.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(url_post)
  request["Content-Type"] = 'application/json'
  request["cnpj-cedente"] = cedente
  request["cnpj-sh"] = sh
  request["token-sh"] = token_sh
  request.body = "{\n\"TipoImpressao\" : \"#{tipo_impressao}\",\n  \"Boletos\" : [\n#{id}\n  ]\n}"

  response = http.request(request)
  JSON.parse(response.read_body)
end

def get_boleto(protocolo, cedente, sh, token_sh, tipo_impressao)
  url_get = URI("https://plugboleto.com.br/api/v1/boletos/impressao/lote/#{protocolo}")
  http = Net::HTTP.new(url_get.host, url_get.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(url_get)
  request["cnpj-cedente"] = cedente
  request["cnpj-sh"] = sh
  request["token-sh"] = token_sh

  start_time = Time.now

  while true
    response = http.request(request)
    response_body = response.body

    if response.content_type == 'application/pdf'
      filename = "boleto_impressao#{tipo_impressao}_#{Time.now.strftime('%d-%m-%Y_%H-%M-%S')}.pdf"
      File.open(filename, 'wb') do |file|
        file.write(response_body)
      end
      puts "Tipo de impressão de número #{tipo_impressao}. PDF salvo como #{filename}"
      break
    elsif Time.now - start_time >= 60
      puts "A impressão ainda está em processo após 1 minuto. Encerrando a consulta. Segue protocolo: #{protocolo}"
      break
    else
      puts "Impressão em andamento. Aguardando 12 segundos antes da próxima tentativa..."
      sleep(12)
    end
  end
  puts "―――――――"
end


def main
  tipos_impressao = [0, 1, 2, 3, 4, 5, 6, 99]

  puts "Insira o idintegracao do boleto:"
  print "> "
  id = gets.chomp

  puts "\nInsira o CNPJ do cedente:"
  print "> "
  cedente = gets.chomp

  puts "\nInsira o CNPJ da SH:"
  print "> "
  sh = gets.chomp

  puts "\nInsira o TOKEN da SH:"
  print "> "
  token_sh = gets.chomp

  puts "-------------------------->>>LOGS<<<--------------------------\n\n"

  for tipo in tipos_impressao
    response = post_boleto(id, cedente, sh, token_sh, tipo)
    puts response

    protocolo = response["_dados"]["protocolo"]
    response_status = get_boleto(protocolo, cedente, sh, token_sh, tipo)
    puts response_status
  end
end

main
