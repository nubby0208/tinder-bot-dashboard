class AddPopToLoc < ActiveRecord::Migration[7.0]
  def change
    add_column :locations, :population, :integer
    add_index :locations, :name, unique: true
  end
end

# lines = CSV.read("location.csv")
# lines.each do |l|
#   loc = Location.find_by(name: l[0])
#   loc.population = l[1].gsub(/,/, '').to_i
#   puts "#{loc.name}-#{loc.population}"
#   loc.save!
# end
