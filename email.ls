require! {
  fs, nodemailer
  './data/email/verify.json': verify-template
  './data/email/forgot.json': forgot-template
}

const sender = '"The Databox Team" <no-reply@datashop.amar.io>'


verify-template.html .= split \$$$$
forgot-template.html .= split \$$$$

send = do
  trans = nodemailer.create-transport!
  -> trans.send-mail it

# TODO: Un-hardcode
to-url = (email, hash) -> "http://datashop.amar.io/user/verify?email=#{encodeURIComponent email}&hash=#hash"

# TODO: Implement string format

verify = (email, username, hash) ->
  link = to-url email, hash
  args = [ username, link, link ]
  html = verify-template.html[0]
  for part, i in args
    html += args[i] + verify-template.html[i + 1]

  send {
    from:    sender
    to:      email
    subject: verify-template.subject
    html:    html
  }

forgot = (email, username, hash) ->
  link = to-url email, hash
  args = [ username, link, link ]
  html = forgot-template.html[0]
  for i, part of args
    html += args[i] + forgot-template.html[i + 1]

  send {
    from:    sender
    to:      email
    subject: forgot-template.subject
    html:    html
  }

export
  verify
  forgot
