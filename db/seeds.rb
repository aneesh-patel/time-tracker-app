# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

aneesh = User.create!(name: 'aneesh', email: 'patel.aneeesh@gmail.com', password_digest: 'foobar')
source1 = Source.create!(name: 'harvest', access_token: '2693794.pt.PsGJ7k_Tpcn63qb9rNaD7D6wmunEXpEkoZ5IvbbgwYAusXWtY6SRcoeHpm1sNPfJxiDzmMCqB1pjkukAoI3d6A', account_id: '1460632', user_id: aneesh.id)
harvest_workspace = Workspace.create!(original_id: '1', source_name: 'harvest', source_id: source1.id)

