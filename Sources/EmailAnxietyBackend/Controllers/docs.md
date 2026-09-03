Plan for converting existing RPN API to REST

/users ------

:user is the specific backend code to recognize the user (given when you call PUT /users/:gmail)
:gmail is the email associated with the user
:emailId is the emailId code to recognize the email draft returned by the PUT /users/:user/drafts

PUT /users/:gmail "register the user with the backend (sets up a watch on the gmail account)"

GET /users/:user/drafts "get the drafts associated with the user account"

PUT /users/:user/drafts "puts the draft in the users mailbox, and returns the emailId"

PATCH /users/:user/drafts/:emailId "edits the specific draft"

POST /users/:user/drafts/:emailId "sends the given draft"
 
POST /users/:user "called by google pub/sub to notify the user of new messages"


-----------

GET /vapidKey "returns the public key associated with the PWA"
