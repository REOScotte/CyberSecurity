# Fix email
I had some inconsistencies with my email address and name for some commits. This script fixes all existing commits. Note that this will mean anyone that's already cloned your repository will have to re-clone it, which may cause them issues if they're making changes. Fortunately, I'm a one man shop so it doesn't affect me. The best plan is to set your email correctly to begin with and avoid this issue altogether.

Change the 3 variables at the top and run this from bash:

```
git filter-branch --force --env-filter '
WRONG_EMAIL="incorrect@email.com"
NEW_NAME="Whatever you want your name to be"
NEW_EMAIL="better@email.com"

git config user.email $NEW_EMAIL
git config user.name $NEW_NAME

if [ "$GIT_COMMITTER_EMAIL" = "$WRONG_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$NEW_NAME"
    export GIT_COMMITTER_EMAIL="$NEW_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$WRONG_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$NEW_NAME"
    export GIT_AUTHOR_EMAIL="$NEW_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
git push --force
```

Most of the code come from:
https://help.github.com/articles/changing-author-info/

I'm running it in place on an existing repo, which may be dangerous, but it worked for me and I hope not to need it again.
I added --force after git filter-branch because I re-ran it a few times while experimenting. I also added the git config commands to set the correct address for future commits.

# Change where remote master lives
I wanted to move a repository from VSTS to GitHub, but had to change my local repo to point to github.

```
git remote set-url origin https://github.com/REOScotte/AdventOfCode.git
```