exports.authenticate = (params, cb) ->
  get_user_id_for_email params.email, (user_id) ->
    if user_id
      validate_user_login user_id, params.pw, (success) ->
        if (success)
          cb({success: true, user_id: user_id})
        else
          cb({success: false, error_reason: "Password is wrong!"})
    else
      cb({success: false, error_reason: "User does not exist!"})
  

get_user_id_for_email = (email, cb) ->
  R.hget "dj:emails", email, (err, user_id) ->
    cb user_id
  
validate_user_login = (user_id, password, cb) ->
  R.hget "dj:ids", user_id, (err, user_attributes) ->
    console.log user_attributes["pw"]
    if password == user_attributes.pw
      cb true
    else
      cb false