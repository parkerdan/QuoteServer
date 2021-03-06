class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_action :check_api_key


  def convert_user_quote
    @apikey = Apikey.find_by key: request.headers["Quote-API-Key"]
    @apikey.increment!(:post_counter)
    @key = Rails.application.config.mashape_yoda_api_key
    Yodaspeak.credentials(@key)

    @user_quote = ActiveSupport::JSON.decode(request.raw_post)["quote"]
    @author = ActiveSupport::JSON.decode(request.raw_post)["author"]
    @yoda_object = Yodaspeak.speak(@user_quote)
    if @yoda_object.body.length < 110 && @yoda_object.code == 200
      @yoda_speak = @yoda_object.body
    else
      @yoda_speak = "Down my translating service is, try later you should"
    end
    @pirate_speak = TalkLikeAPirate.translate(@user_quote)

    @reply= @reply.to_a << {:author => @author.titleize,:quote => @user_quote,:yoda_speak => @yoda_speak,:pirate_speak =>@pirate_speak}


    render :json => {
      :response => @reply,
    },:status => 200

  end

  def get_quote
    @apikey = Apikey.find_by key: request.headers["Quote-API-Key"]
    @apikey.increment!(:get_counter)
    # check_header
    # @var = request.raw_post
    # @var = TalkLikeAPirate.translate(ActiveSupport::JSON.decode(request.raw_post)["quote"])
     Quote.where("yoda_speak != ''").limit(10).order("RANDOM()").each do |q|
      @reply= @reply.to_a << {:author => q.author.titleize,:quote => q.body,:yoda_speak => q.yoda_speak,:pirate_speak =>q.pirate_speak}
    end
    render :json => {
      :response => @reply,
    },:status => 200

  end

  def search_by_author
    @apikey = Apikey.find_by key: request.headers["Quote-API-Key"]
    @apikey.increment!(:search_counter)
    @author = ActiveSupport::JSON.decode(request.raw_post)["author"]
    #
    @quote = Quote.where("author = ? and yoda_speak != ''",@author ).limit(10).order("RANDOM()")
    #
    if @quote.length > 0
      @quote.each do |q|
        @reply= @reply.to_a << {:author => q.author.titleize,:quote => q.body,:yoda_speak => q.yoda_speak,:pirate_speak =>q.pirate_speak}
      end
      render :json => {
        :response => @reply,
      },:status => 200
    else
      render :json => {
        :response => 'No entries for this author',
      },:status => 204

    end

  end


  private

  def check_api_key
    respond_to do |format|
      format.json {
        if !Apikey.find_by key: request.headers["Quote-API-Key"]
          render :json => {
            :message => "Invalid Token",
          }, :status => 498
        end

      }
      format.html { render file: "#{Rails.root}/public/404.html", layout: false, status: 404  }
    end
  end

end
# request.headers["Author"]
# ActiveSupport::JSON.decode()
# curl -H "Content-Type: application/json" -X GET -d '{"quote":"my quote"}' http://localhost:3000/api/quote
