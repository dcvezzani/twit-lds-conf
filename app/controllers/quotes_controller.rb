class QuotesController < ApplicationController
  include TwitterLdsConfFeed

  before_action :set_quote, only: [:show, :edit, :update, :destroy, :favorite]
  before_action :load_quotes, only: [:index, :list]
  before_action :load_tags, only: [:index, :list]

  attr_reader :extra_params

  # GET /quotes
  # GET /quotes.json
  def index
  end

  def conference_quotes
    sub1 = Quote.joins(:tags).select('tags.id').where(['tweet_id >= ?', 782251540421586945]).to_sql.gsub(/\"/, '')
    tag_ids = Tag.where(["id in (#{sub1})"]).where(['value like ? or value like ? or value like ?', 'Pres%', 'Elder%', 'Sister%']).order(:value).select('tags.id').map(&:id)

    quote_tag_fields_01 = "quotes.tweet_id, quotes.id, quotes.tweet_text"
    quote_tag_fields_02 = "tags.value, #{quote_tag_fields_01}"
    @quotes = Quote.joins(:tags).joins(', quotes q2 INNER JOIN tags_quotes tq2 ON tq2.quote_id = q2.id INNER JOIN tags t2 ON t2.id = tq2.tag_id').where('quotes.id = q2.id').where(['tags.id in (?)', tag_ids]).select("tags.value as tag_value, #{quote_tag_fields_01}, string_agg(t2.value, ', ' ORDER BY t2.value) as tag_values").group(quote_tag_fields_02).order(quote_tag_fields_02)

    # @quotes = Quote.find_by_sql("SELECT tags.value as tag_value, quotes.tweet_id, quotes.id, quotes.tweet_text, string_agg(t2.value, ', ' ORDER BY t2.value) as tag_values FROM quotes INNER JOIN tags_quotes ON tags_quotes.quote_id = quotes.id INNER JOIN tags ON tags.id = tags_quotes.tag_id, quotes q2 INNER JOIN tags_quotes tq2 ON tq2.quote_id = q2.id INNER JOIN tags t2 ON t2.id = tq2.tag_id WHERE ((quotes.id = q2.id) and (tags.id in (62,92,74,40,97,20,49,73,63,80,16,19,88,99,90,27,58,56,94,98,57,25,77,23,59,55,101,81,12,95,22))) GROUP BY tags.value, quotes.tweet_id, quotes.id, quotes.tweet_text  ORDER BY tags.value, quotes.tweet_id, quotes.id, quotes.tweet_text")

=begin
rails generate decorator Quote
=end
    # @quotes.map{|x| x.attributes['tag_value']}


    @quotes_by_author = @quotes.inject({}){ |hash, quote| 
      if(!hash.has_key?(quote.tag_value))
        hash[quote.tag_value] = []
      end
      hash[quote.tag_value] << {id: quote.id, tweet_id: quote.tweet_id, tweet_text: quote.tweet_text, tag_values: quote.tag_values}
      hash
    }
    
    respond_to do |format|
      format.html { render :conference_quotes }
      format.json { render :conference_quotes, status: :created, location: @quotes.first }
    end
  end

  def list
    term = params[:term] ? params[:term] : nil
    tags = params[:tags] ? params[:tags] : []
    filterout = params[:filterout] ? params[:filterout] : []
    order = "created_at desc"
    order = "tweet_id desc"

    @quotes_sorted = if(term)
      @quotes.where(["tweet_text like ?", "%#{term}%"]).includes(:tags).order(order).page (params[:page] or 1)

    elsif(!tags.empty?)
      tags = tags.split(/ *, */) unless tags.is_a?(Array)
      filterout = filterout.split(/ *, */) unless filterout.is_a?(Array)

      # select all quotes that have all given tags
      sub1 = Quote.joins(:tags).select('quotes.id, tags.value tvalue').where(["tags.value in (?)", tags]).to_sql.gsub(/\"/, '')
      wtags_ids = Quote.find_by_sql(["select q1.id from (#{sub1}) as q1 group by q1.id having count(distinct q1.tvalue) > ?", (tags.length-1)]).map(&:id)

      # select all records that should be filtered out
      filter_out_ids = @quotes.joins(:tags).where(["tags.value in (?)", filterout]).map(&:id)

      filtered_quotes = @quotes.where(['id in (?)', wtags_ids])
      filtered_quotes = filtered_quotes.where(['id not in (?)', filter_out_ids]) unless filter_out_ids.empty?
      filtered_quotes.includes(:tags).order(order).page (params[:page] or 1)
    else
      #@quotes.includes(:tags).order(order).page (params[:page] or 1)
      hide_ids = @quotes.joins(:tags).where(["tags.value in ('hide')"]).map(&:id)
      @quotes.where(['id not in (?)', hide_ids]).includes(:tags).order(order).page (params[:page] or 1)
    end
  end

  # GET /lds_conf_feed
  # GET /lds_conf_feed?feed[:count]=20
  # GET /lds_conf_feed.json
  def lds_conf_feed
    resp = fetch_twitter_lds_conf_feed(feed_params[:count].to_i, feed_params[:screen_name])
    render json: resp.body, status: resp.code
  end

  # GET /quotes/1
  # GET /quotes/1.json
  def show
  end

  # GET /quotes/latest
  # GET /quotes/latest.json
  def latest
    @quote = Quote.where(['id in (select id from quotes where created_at in (select max(created_at) max_created_at from quotes))']).first
    render action: :latest, layout: false
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
      if @quote.save and @quote.add_tags!(extra_params[:tag])
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
      if @quote.update_with_tag(quote_params, extra_params)
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

    def load_tags
      sub1 = Quote.joins(:tags).select('tags.id').where(['tweet_id >= ?', 782251540421586945]).to_sql.gsub(/\"/, '')
      @tags = Tag.where(["id in (#{sub1})"]).where(['value like ? or value like ? or value like ?', 'Pres%', 'Elder%', 'Sister%']).order(:value)
      # @tags = Tag.where(['value like ? or value like ? or value like ?', 'Pres%', 'Elder%', 'Sister%']).order(:value)
    end

    def load_quotes
      order = "tweet_id desc"
      @quotes = Quote.all.includes(:tags).order(order)
      # @quotes = Quote.where(['tweet_id >= ?', 782251540421586945]).includes(:tags).order(order)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def quote_params
      p = params.require(:quote).permit(:tweet_id, :tweet_text, :tag, :apply, tags_attributes: [:id, :value, :_destroy])

      @extra_params = {
        tag: p.delete(:tag), 
        is_applied: (p.delete(:apply).to_s == "true")
      }

      p
    end

    def feed_params
      (params[:feed]) ? params[:feed].permit(:count, :screen_name) : {}
    end

    def load_sorted_quotes
      @quotes_sorted = @quotes.includes(:tags).order("tweet_id desc").page (params[:page] or 1)
    end
end
