class SearchController < ApplicationController
  def search
    if Search.count.zero? # Fix search on empty table error msg
      redirect_to doc_path
    else
      @query = params[:q].present? ? params[:q] : '*'
      @documents = Search.search( @query,
        fields: [:title, :content],
        highlight: {fields: {content: {fragment_size: 100}}},
        suggest: true,
        match: :phrase,
        page: params[:page],
        # If there are fewer than 5 result, perform second search with misspellings
        misspellings: {edit_distance: 3, below: 5},
        per_page: 6)
      end
  end

  def advanced_search
  end
end
