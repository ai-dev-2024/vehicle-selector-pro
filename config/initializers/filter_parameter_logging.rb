Rails.application.config.filter_parameters += %i[
  passw email phone secret token _key crypt salt certificate otp ssn
]
