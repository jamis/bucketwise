module TagsHelper
  def possible_receiver_tags
    @possible_receiver_tags ||= (subscription.tags - [tag_ref]).sort_by(&:name)
  end
end
