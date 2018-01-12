# AirCasting - Share your Air!
# Copyright (C) 2011-2012 HabitatMap, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# You can contact the authors by email at <info@habitatmap.org>

class FixedSession < Session
  STREAMS_IN_SESSION = 16

  validates :is_indoor, inclusion: { in: [true, false] }
  validates :latitude, :longitude, presence: true

  def self.streaming
    where(last_measurement_at: Time.at(1.hour.ago)..Time.now)
  end

  def self.filtered_json_fields
    [:id, :title, :start_time_local, :end_time_local, :is_indoor, :latitude, :longitude]
  end

  def self.filtered_streaming_json(data)
    streaming
    .with_user_and_streams
    .filter(data)
    .as_json(
      only: filtered_json_fields,
      methods: [:username, :streams, :last_hour_average]
    )
  end

  def after_measurements_created
    update_measurements_received_count
    notify_gcm
    update_end_time
    self.save!
  end

  def last_hour_average
    stream = self.streams.length >= 1 ? self.streams.first : nil
    return unless stream

    last_measurement_time = stream.measurements.last.time
    measurements = stream.measurements.where(time: last_measurement_time - 1.hour..last_measurement_time)
    last_hour_average = measurements.average(:value)

    last_hour_average
  end

  def as_synchronizable(stream_measurements=false)
    as_json(methods: [:streams], stream_measurements: stream_measurements)
  end

  def as_json(opts=nil)
    opts ||= {}

    methods = opts[:methods] || [:notes, :calibration]
    methods << :type

    res = super(opts.merge(methods: methods))
  end
 
  private

  def update_measurements_received_count
    self.increment(:measurements_received_count, 1)
  end

  def notify_gcm
    return unless measurements_received_count >= STREAMS_IN_SESSION

    GcmNotifier.new(self.user.gcm_token, self.id).call
    self.measurements_received_count = 0
  end

  def update_end_time
    self.end_time = self.measurements.maximum('time')
    self.end_time_local = self.measurements.maximum('time')
    self.last_measurement_at = DateTime.current
  end
end
