module BucketsHelper
  def source_view
    params[:view] || "index"
  end
end
