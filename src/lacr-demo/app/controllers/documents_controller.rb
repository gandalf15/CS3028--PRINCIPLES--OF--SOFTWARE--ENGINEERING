class DocumentsController < ApplicationController

  def index
    @documents = Search.select(:page, :volume).distinct.order(volume: :asc, page: :asc).group(:volume, :page).paginate(:page => params[:page], :per_page => 10)
  end

  def list
    @documents = Search.select(:page, :volume).distinct.order(volume: :asc, page: :asc).group(:volume, :page)
    respond_to do |format|
      format.html { redirect_to doc_path }
      format.json { render json: @documents }
      format.js   { render :layout => false }
    end
  end

  def new
    if not user_signed_in? or not current_user.admin?
      redirect_to new_user_session_path
    end
  end

  def show
    if params.has_key?(:p) and params.has_key?(:v) \
      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
      # Store the volume and page from the input
      @volume, @page = params[:v].to_i, params[:p].to_i
    else
      redirect_to doc_path, notice:  "The document has not been found."
    end
  end

  def page
    if params.has_key?(:p) and params.has_key?(:v) \
      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
      # Store the volume and page from the input
      @volume, @page = params[:v].to_i, params[:p].to_i
      # Select Documents
      @documents = Search.where('volume' => @volume).rewhere('page' => @page)
      if @documents.length > 0
        # Select image
        page_image = PageImage.find_by_volume_and_page(@volume, @page)
        if page_image # Has been uploaded
          # Simple Fix of the file extension after image convert
          @document_image_normal = page_image.image.normal.url.split('.')[0...-1].join + '.jpeg'
          @document_image_large = page_image.image.large.url.split('.')[0...-1].join + '.jpeg'
        end
        respond_to do |format|
         format.html { render :partial => "documents/page" }
       end

      else
        render status: 500
      end
    else
      render status: 500
    end
  end

  def upload
    if user_signed_in? and current_user.admin?
        @succesfully_uploaded = {xml:[], image:[]}
        @unsuccesfully_uploaded = {xml:[], image:[]}
        if params.has_key?(:transcription_xml)
          xml_files = xml_upload_params
          # Save all uploaded xml files, call method ...
          xml_files['xml'].each do |file|

            # Check namespace
            if (Nokogiri::XML(File.open(file.path))).collect_namespaces.values.include? TranscriptionXml::HISTEI_NS
              t = TranscriptionXml.new
              t.xml = file
              if t.save!
                t.histei_split_to_paragraphs
                @succesfully_uploaded[:xml].push(file.original_filename)
              end
            else
              @unsuccesfully_uploaded[:xml].push("HisTEI namespace not found: #{file.original_filename}")
            end
          end
          Search.reindex()
      end

      if params.has_key?(:page_image)
        image_files = image_upload_params
        # Save all uploaded image files, call method ...
        image_files['image'].each do |file|
          t = PageImage.new
          t.image = file
          t.parse_filename_to_volume_page file.original_filename
          if t.save!
            @succesfully_uploaded[:image].push(file.original_filename)
          else
            @unsuccesfully_uploaded[:image].push(file.original_filename)
          end
        end
      end
    else
      redirect_to new_user_session_path
    end
  end

  def destroy
    if user_signed_in? and current_user.admin?
    else
      redirect_to new_user_session_path
    end
  end

  private  # all methods that follow will be made private: not accessible for outside objects
    def xml_upload_params
      if user_signed_in? and current_user.admin?
        params.require(:transcription_xml).permit xml: []
      else
        redirect_to new_user_session_path
      end
    end

    def image_upload_params
      if user_signed_in? and current_user.admin?
        params.require(:page_image).permit image: []
      else
        redirect_to new_user_session_path
      end
    end
end
