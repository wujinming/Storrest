class Node < ActiveRecord::Base
  NUM_CHILDREN_NEEDED = 5
  NUM_RATINGS_NEEDED = 5

  belongs_to :parent_story, :class_name => "Story", :foreign_key => "parent_story_id"
  belongs_to :parent_node, :class_name => "Node", :foreign_key => "parent_node_id"
  has_many :children, :class_name => "Node", :foreign_key => "parent_node_id"
  has_many :ratings

  def as_json(options = {})
    {
      text: self.text,
      is_active: self.is_active,
      parent:       self.parent_node_id,
      id: self.id
    }
  end

  def render_to_text_after_node(node)
    if self.parent_node == node
      return self.text
    else
      return self.parent_node.render_to_text_after_node(node) + " " + self.text
    end
  end

  def render_to_text
    render_to_text_after_node(nil)
  end

  def youngest_common_ancestor(other_node)
    nodes = [self, other_node]
    until nodes[0].id == nodes[1].id
      oldest_node_index = nodes[0].created_at > nodes[1].created_at ? 0 : 1
      nodes[oldest_node_index] = nodes[oldest_node_index].parent_node
      if nodes[oldest_node_index].nil? # They have no common ancestor...
        return nil
      end
    end
    return nodes[0]
  end

  def length_of_story_so_far
    if self.parent_node.nil?
      return 1
    else
      return 1 + self.parent_node.length_of_story_so_far
    end
  end

  def avg_score_for_total_rating
    total = 0
    (0..3).each do |rating_num|
      total += self.avg_score_for_rating(rating_num)
    end
    return total * 1.0 / 4
  end

  def avg_score_for_rating(rating_num)
    total = 0
    self.ratings.each do |rating|
      total += rating.rating_array[rating_num]
    end
    return total * 1.0 / self.ratings.size
  end

  def kill
    self.is_active = false
    self.contributions_completed = true
    self.ratings_completed = true
    self.save
  end

  def keep
    if self.parent_story.length - self.length_of_story_so_far <= 0
      self.is_active = false
      self.contributions_completed = true
      self.ratings_completed = true
      self.is_story_ending = true
    else
      self.is_active = false
      self.ratings_completed = true
    end
    self.save
  end

end
