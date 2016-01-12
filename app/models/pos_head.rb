class PosHead
  
  def self.get_list
    # PosHeadsController.helpers.get_pos_heads(12, 0, "label", "asc")["pos_heads"].map{|x| x["label"]}
    WhitelabBackend.instance.get_pos_heads(12, 0, "label", "asc")["pos_heads"].map{|x| x["label"]}
  end
  
end