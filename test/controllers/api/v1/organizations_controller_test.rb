require "controllers/api/v1/test"

class Api::V1::OrganizationsControllerTest < Api::Test
def setup
  # See `test/controllers/api/test.rb` for common set up for API tests.
  super

  @organization = build(:organization, team: @team)
  @other_organizations = create_list(:organization, 3)

  @another_organization = create(:organization, team: @team)

  # 🚅 super scaffolding will insert file-related logic above this line.
  @organization.save
  @another_organization.save

  @original_hide_things = ENV["HIDE_THINGS"]
  ENV["HIDE_THINGS"] = "false"
  Rails.application.reload_routes!
end

def teardown
  super
  ENV["HIDE_THINGS"] = @original_hide_things
  Rails.application.reload_routes!
end

# This assertion is written in such a way that new attributes won't cause the tests to start failing, but removing
# data we were previously providing to users _will_ break the test suite.
def assert_proper_object_serialization(organization_data)
  # Fetch the organization in question and prepare to compare it's attributes.
  organization = Organization.find(organization_data["id"])

  assert_equal_or_nil organization_data['name'], organization.name
  # 🚅 super scaffolding will insert new fields above this line.

  assert_equal organization_data["team_id"], organization.team_id
end

test "index" do
  # Fetch and ensure nothing is seriously broken.
  get "/api/v1/teams/#{@team.id}/organizations", params: {access_token: access_token}
  assert_response :success

  # Make sure it's returning our resources.
  organization_ids_returned = response.parsed_body.map { |organization| organization["id"] }
  assert_includes(organization_ids_returned, @organization.id)

  # But not returning other people's resources.
  assert_not_includes(organization_ids_returned, @other_organizations[0].id)

  # And that the object structure is correct.
  assert_proper_object_serialization response.parsed_body.first
end

test "show" do
  # Fetch and ensure nothing is seriously broken.
  get "/api/v1/organizations/#{@organization.id}", params: {access_token: access_token}
  assert_response :success

  # Ensure all the required data is returned properly.
  assert_proper_object_serialization response.parsed_body

  # Also ensure we can't do that same action as another user.
  get "/api/v1/organizations/#{@organization.id}", params: {access_token: another_access_token}
  assert_response :not_found
end

test "create" do
  # Use the serializer to generate a payload, but strip some attributes out.
  params = {access_token: access_token}
  organization_data = JSON.parse(build(:organization, team: nil).api_attributes.to_json)
  organization_data.except!("id", "team_id", "created_at", "updated_at")
  params[:organization] = organization_data

  post "/api/v1/teams/#{@team.id}/organizations", params: params
  assert_response :success

  # # Ensure all the required data is returned properly.
  assert_proper_object_serialization response.parsed_body

  # Also ensure we can't do that same action as another user.
  post "/api/v1/teams/#{@team.id}/organizations",
    params: params.merge({access_token: another_access_token})
  assert_response :not_found
end

test "update" do
  # Post an attribute update ensure nothing is seriously broken.
  put "/api/v1/organizations/#{@organization.id}", params: {
    access_token: access_token,
    organization: {
      name: 'Alternative String Value',
      # 🚅 super scaffolding will also insert new fields above this line.
    }
  }

  assert_response :success

  # Ensure all the required data is returned properly.
  assert_proper_object_serialization response.parsed_body

  # But we have to manually assert the value was properly updated.
  @organization.reload
  assert_equal @organization.name, 'Alternative String Value'
  # 🚅 super scaffolding will additionally insert new fields above this line.

  # Also ensure we can't do that same action as another user.
  put "/api/v1/organizations/#{@organization.id}", params: {access_token: another_access_token}
  assert_response :not_found
end

test "destroy" do
  # Delete and ensure it actually went away.
  assert_difference("Organization.count", -1) do
    delete "/api/v1/organizations/#{@organization.id}", params: {access_token: access_token}
    assert_response :success
  end

  # Also ensure we can't do that same action as another user.
  delete "/api/v1/organizations/#{@another_organization.id}", params: {access_token: another_access_token}
  assert_response :not_found
end
end
