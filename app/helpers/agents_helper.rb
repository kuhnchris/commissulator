module AgentsHelper
  def deals_by agent
    link_to agent.reference, :filtered_attribute => :agent_id, :filter_value => agent.id
  end
end
