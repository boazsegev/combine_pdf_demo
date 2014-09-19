class WelcomeController < ApplicationController
  def initialize
    super.initialize
    @rescue_template = <<ENDCODE
# There is no action to perform without any files.
return if params[:file_0].nil?
# catch any exception and tell the user which PDF caused the exception.
begin
%s
# tell the user which PDF caused the exception
rescue Exception => e
  redirect_to bates_url, notice: ( I18n.t(:bates_file_unsupported_error) + "\n\#{file_name}")
end
ENDCODE

    @fonts_code = <<ENDCODE
  # register UNICODE fonts if necessary
  unless CombinePDF::Fonts.get_font :david
    fonts = CombinePDF.new(Rails.root.join("app", "assets", "fonts", "david+bold.pdf").to_s).fonts(true)
    CombinePDF.register_font_from_pdf_object :david, fonts[0]
    CombinePDF.register_font_from_pdf_object :david_bold, fonts[2]
  end
ENDCODE

    @combine_code = <<ENDCODE
ENDCODE

    @title_page_code = <<ENDCODE
ENDCODE

    @bates_code = <<ENDCODE
#{@fonts_code}

  # container for complete pdf
  completed_pdf = CombinePDF.new

  #### set globals
  file_name = ''
  output_name = ( Date.today.strftime '%Y%m%d output.pdf' )
  first_page_number = params[:first_page_number] || 1
  first_index_number = params[:first_index_number] || 1
  params[:first_page_is_cover] ||= false

  #### set page stamp template
  ## top and buttom template
  pdfs_pages_count = []
  pdf_dates = []
  pdf_titles = []
  ignore_first_file = params[:first_page_is_cover]
  first_page = nil
  mediabox = nil

  #string to update: number_page_template[:Contents][:referenced_object][:raw_stream_content]
  params.each do |k,v|
    if k.to_s =~ /file_/
      # for now, count page numbers to make index before calaculating final page count and combining
      file_name = v[:name]

      # parse the pdf data
      warn "Parsing \#{file_name}"
      pdf_file = CombinePDF.parse(
        Base64.urlsafe_decode64(
          v[:data].slice( "data:application/pdf;base64,".length,
            v[:data].length )) )
      pdf_file_pages = pdf_file.pages
      pdfs_pages_count << pdf_file_pages.length

      # create and add title page to arrays.
      if ignore_first_file && first_page.nil?
        ignore_first_file = false
        pdf_dates << ""
        pdf_titles << ""
        first_page = pdf_file
      else
        # set title page mediabox size
        mediabox ||= pdf_file_pages[0][:CropBox] || pdf_file_pages[0][:MediaBox]
        # create title page and write content
        title_page = CombinePDF.create_page mediabox
        title_page.textbox( "\#{t :bates_pdf_file} \#{pdfs_pages_count.length + first_index_number - 1}" ,
          max_font_size: 34,
          font: :david,
          y: (mediabox[3] - mediabox[1])/2 )
        title_page.textbox v[:title], max_font_size: 36, font: :david_bold
        title_page.textbox v[:date], max_font_size: 24, font: :david, height: (mediabox[3] - mediabox[1])/2
        completed_pdf << title_page
        page_count = pdfs_pages_count.pop + 1
        pdfs_pages_count << page_count
        pdf_dates << v[:date]
        pdf_titles << v[:title]
        completed_pdf << pdf_file
      end
    end
  end

  # create index pdf
  warn "Creating Index File"
  ignore_first_file = params[:first_page_is_cover]
  table_options = {  font: :david,
    header_font: :david_bold,
    max_font_size: 12,
    column_widths: [3, 10, 30, 4],
    table_data: [] }
  table_options[:headers] = [ (t :bates_pdf_file),
    (t :bates_pdf_date),
    (t :bates_pdf_title),
    (t :bates_pdf_page) ]
  index_page_length = pdfs_pages_count.length / 24
  index_page_length += 1 if pdfs_pages_count.length % 24 > 0
  page_number = first_page_number + index_page_length
  index_count = 0
  pdfs_pages_count.each_index do |i|
    unless ignore_first_file
      table_options[:table_data] << [ (first_index_number + index_count).to_s,
        pdf_dates[i], pdf_titles[i], page_number ]
      index_count += 1
    end
    ignore_first_file = false
    page_number += pdfs_pages_count[i]
  end

  if I18n.locale == :he
    table_options[:direction] = :rtl
  end
  index_pdf = CombinePDF.create_table table_options

  title_page = index_pdf.pages[0] 
  title_page.textbox (t :bates_pdf_index),
    { y: ((title_page.mediabox[3] - title_page.mediabox[1])*0.91),
      height: ((title_page.mediabox[3] - title_page.mediabox[1])*0.03),
      font: :david,
      max_font_size: 24,
      text_valign: :bottom  }
  completed_pdf >> index_pdf

  # # add index pdf to the begining (or after the first) of the piles
  # if index_pdf
  #   add_index = 0
  #   add_index = 1 if params[:first_page_is_cover]
  #   pdfs.insert add_index, index_pdf
  #   pdfs_pages.insert add_index, index_pdf.pages
  #   pdfs_pages_count.insert add_index, pdfs_pages[add_index].length
  # end

  # no prawn, only PDFWriter
  first_page_number += pdfs_pages_count[0] if params[:first_page_is_cover]
  completed_pdf.number_pages({ start_at: first_page_number,
    font_name: :david,
    font_size: 14,
    font_color: [0,0,0.4],
    box_color: [0.8, 0.8, 0.8],
    border_width: 1,
    border_color: [0.3,0.3,0.3],
    box_radius: 8,
    number_location: [:top, :bottom],
    opacity: 0.75
  })

  # add first file if it was skipped
  if params[:first_page_is_cover] && !first_page.nil?
    completed_pdf >> first_page
  end

  warn "Completed injections - starting to format PDF file output."
  if completed_pdf.pages.length > 0
    completed_pdf.version = [completed_pdf.version, 1.6].max
    send_data completed_pdf.to_pdf, type: 'application/pdf', filename: output_name
    return        
  else
    redirect_to bates_url, notice: (I18n.t :bates_unknown_zero_pages_error)
  end

ENDCODE
  end
  def welcome
    @content = t(:welcome_page)
    @content.gsub! "combine_pdf", ("\"combine_pdf\":https://rubygems.org/gems/combine_pdf")
    @content.gsub! "bates", ("\"bates\":%s" % bates_path)
    @content.gsub! /Let's get started!/, ("\"Let’s get started!\":%s" % combine_path)
    render inline: RedCloth.new( @content ).to_html, layout: true
  end

  def combine
    @content = t(:welcome_page)
    @content.gsub! "bates", ("\"bates\":%s" % bates_path)
    render inline: RedCloth.new( @content ).to_html, layout: true
  end

  def stamp
  end

  def number
  end

  def tables
  end

  def fonts
  end

  def bates
    @code = @rescue_template % @bates_code
    eval @code
  end
end
