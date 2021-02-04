source env.var

gcloud pubsub topics create scc-topic
gcloud pubsub subscriptions create scc-subscription --topic $TOPIC_ID

#For permissions if needed

#export GCLOUD_ACCOUNT=your-username@email.com
#export EMAIL=service-account-name@$CONSUMER_PROJECT.iam.gserviceaccount.com

#  gcloud pubsub topics add-iam-policy-binding \
#    projects/$PUBSUB_PROJECT/topics/$TOPIC_ID \
#    --member="user:$GCLOUD_ACCOUNT" \
#    --role='roles/pubsub.admin'

#  gcloud organizations add-iam-policy-binding $ORGANIZATION_ID \
#    --member="user:$GCLOUD_ACCOUNT" \
#    --role='role-name'

  # The topic to which the notifications are published
  export PUBSUB_TOPIC="projects/$PUBSUB_PROJECT/topics/$TOPIC_ID"

  # The description for the NotificationConfig
  export DESCRIPTION="Notifies for SCC active findings"

  # Filters for active findings
  export FILTER="state=\"ACTIVE\""

  gcloud scc notifications create scc-notification \
    --organization "$ORGANIZATION_ID" \
    --description "$DESCRIPTION" \
    --pubsub-topic $PUBSUB_TOPIC \
    --filter "$FILTER"