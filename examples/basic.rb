
include Stella::DSL

testplan :basic do
  desc "A basic demonstration of the testplan DSL"

  get "/products" do
    name "View Products"

    response 200 do |header, body|
      data = YAML.load(body)
      #repeat :times => 2, :wait => 1      # Repeat this request
    end
  end

  get "/product/:id" do
    name "Product #{params[:id]}"
    response 200 do |header, body|
      data = YAML.load(body)
    end
  end

end