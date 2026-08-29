class GraphqlController < ApplicationController
  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    
    result = VehicleSelectorProSchema.execute(
      query,
      variables: variables,
      operation_name: operation_name,
      context: graphql_context
    )

    render json: result
  end

  private

  def graphql_context
    {
      shop: current_shop,
      current_user: current_user
    }
  end

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      ambiguous_param.present? ? JSON.parse(ambiguous_param) : {}
    when Hash, ActionController::Routing::RouteSet::NamedRouteCollection
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
