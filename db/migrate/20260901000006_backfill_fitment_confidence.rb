class BackfillFitmentConfidence < ActiveRecord::Migration[7.1]
  def up
    VehicleProductFitment.where.not(fitment_type: nil).find_each do |fitment|
      score = VehicleProductFitment::CONFIDENCE_BY_TYPE.fetch(fitment.fitment_type.to_s, 0.9)
      next if fitment.confidence_score == score

      # rubocop:disable Rails/SkipsModelValidations -- data backfill of derived
      # column; running validations/callbacks would enqueue sync jobs per row.
      fitment.update_column(:confidence_score, score)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    # No-op: confidence scores are derived data; reverting the column is enough.
  end
end
