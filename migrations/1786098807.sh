echo "Relink agent skill symlinks to default/agents/skills/omisu"

mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$OMISU_PATH/default/agents/skills/omisu" ~/.agents/skills/omisu
ln -sfn "$OMISU_PATH/default/agents/skills/omisu" ~/.claude/skills/omisu
ln -sfn "$OMISU_PATH/default/agents/skills/omisu" ~/.codex/skills/omisu
ln -sfn "$OMISU_PATH/default/agents/skills/omisu" ~/.pi/agent/skills/omisu
