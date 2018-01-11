class AddMeasurementsReceivedCountToSessions < ActiveRecord::Migration
  def change
    add_column :sessions, :measurements_received_count, :integer, default: 0
  end
end
