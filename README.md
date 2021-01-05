# django

expected directory structure:
~/dev/

from ~/dev/ run AppMaker.sh with 2 arguments:
-a the name of your project
-b the name of your app (this is also the name of your model)

eg.

bash AppMaker.sh -a Budgetty -b Transactions

this will create a django project called Budgetty containing an app called Transactions.
the models.py will contain a model called transactions;
by default this model will contain fields for title, description and image but I plan to make this configurable via arguments in the future.

it will also create 3 views:
- a list of all objects
- a form to add new objects
- a form to update previous objects

and 3 html templates
- a base template with a navbar to all pages
- an index template with a list of cards showing all object info
- a form

static assets exist in ~dev/your_project/static and include
images/logo.png
images/favicon.ico
images/placeholder.png
