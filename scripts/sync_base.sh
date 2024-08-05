#! /bin/bash

# Store current position.
curDir=`pwd`
# Switch to working position, which is the root of the project.
workDir=$(cd "$(dirname "$0")/..";pwd)
cd $workDir

# ======

# Step 1: clone base repository.
if [ ! -d ".base_repo" ]; then
    git clone https://github.com/ZIJI-CS/F-MkDocs-Template.git .base_repo
fi

# Step 2: before syncing, storage changes not committed.
if [ -n "$(git status --porcelain)" ]; then
    echo "There are uncommitted changes in the current repository. Please commit or stash these changes first!"
    echo "当前仓库存在未提交的更改，请先提交或者存储这些更改！"
    exit 0
fi

# Step 3: pack patches according to `.base_commit`.
baseCommitHash=`cat .base_commit`
cd .base_repo
git pull  # update the base repository, in case the base repository has been updated
git format-patch --stdout $baseCommitHash..HEAD -- ":(exclude).cache" > sync_patch.patch

# Step 4: store the latest base commit.
git log -1 --pretty=format:%H > ../.base_commit_latest

# Step 5: apply patches to the current repository.
cd ..
if ! git apply --reject --whitespace=fix .base_repo/sync_patch.patch; then
    echo "Failed to apply patches. Please check the conflict files and resolve them manually!"
    echo "无法应用补丁，请检查冲突文件并手动解决！"
    exit 0
fi

# Step 6: apply the commit_base.
mv .base_commit_latest .base_commit

# Step 7: commit the changes.
git add -A
git commit -m "update: sync base repository"

# ======

# Recover the current position.
cd $curDir