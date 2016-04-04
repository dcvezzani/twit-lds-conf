class QuotesController < ApplicationController
  include TwitterLdsConfFeed

  before_action :set_quote, only: [:show, :edit, :update, :destroy]
  before_action :load_quotes, only: [:index, :list]

  # GET /quotes
  # GET /quotes.json
  def index
  end

  def list
    term = params[:term] ? params[:term] : nil

    @quotes_sorted = if(term)
      @quotes.where(["tweet_text like ?", "%#{term}%"]).includes(:tags).order("tweet_id desc").page (params[:page] or 1)
    else
      @quotes.includes(:tags).order("tweet_id desc").page (params[:page] or 1)
    end
  end

  # GET /lds_conf_feed
  # GET /lds_conf_feed?feed[:count]=20
  # GET /lds_conf_feed.json
  def lds_conf_feed
    resp = fetch_twitter_lds_conf_feed(feed_params[:count].to_i)
    render json: resp.body, status: resp.code
  end

  # GET /quotes/1
  # GET /quotes/1.json
  def show
  end

  # GET /quotes/new
  def new
    @quote = Quote.new
  end

  # GET /quotes/1/edit
  def edit
  end

  # POST /quotes
  # POST /quotes.json
  def create
    @quote = Quote.new(quote_params)

    respond_to do |format|
      if @quote.save
        format.html { redirect_to @quote, notice: 'Quote was successfully created.' }
        format.json { render :show, status: :created, location: @quote }
      else
        format.html { render :new }
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /quotes/1
  # PATCH/PUT /quotes/1.json
  def update
    respond_to do |format|
      if @quote.update(quote_params)
        format.html { redirect_to @quote, notice: 'Quote was successfully updated.' }
        format.json { render :show, status: :ok, location: @quote }
      else
        format.html { render :edit }
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quotes/1
  # DELETE /quotes/1.json
  def destroy
    @quote.destroy
    respond_to do |format|
      format.html { redirect_to quotes_url, notice: 'Quote was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_quote
      @quote = Quote.find(params[:id])
    end

    def load_quotes
      @quotes = Quote.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def quote_params
      params.require(:quote).permit(:tweet_id, :tweet_text)
    end

    def feed_params
      (params[:feed]) ? params[:feed].permit(:count) : {}
    end

    def load_sorted_quotes
      @quotes_sorted = @quotes.includes(:tags).order("tweet_id desc").page (params[:page] or 1)
    end
end
