# Set identification from install inputs
if [[ -n ${OMISU_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$OMISU_USER_NAME"
fi

if [[ -n ${OMISU_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$OMISU_USER_EMAIL"
fi
