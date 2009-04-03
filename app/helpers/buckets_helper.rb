module BucketsHelper
  def source_view
    params[:view] || "index"
  end

  def possible_receiver_buckets
    account.buckets - [bucket]
  end
end
