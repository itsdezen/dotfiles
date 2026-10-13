import { Plugin } from "@opencode/plugin/tui"

export default Plugin.define({
  id: "auto-approve",
  setup(context) {
    // Runtime-only flag. Memory storage is discarded when the TUI exits, so
    // toggling never writes cli.json or the server's saved-permission store.
    const [state, update] = context.storage.memory("auto-approve", {
      initial: { enabled: false },
    })

    // While enabled, answer every pending permission prompt with a one-time
    // allow. This mirrors `opencode --auto` without persisting anything.
    context.data.on("permission.asked", async (event) => {
      if (!state.enabled) return
      try {
        await context.client.permission.reply({
          sessionID: event.data.sessionID,
          requestID: event.data.id,
          decision: "once",
        })
      } catch (error) {
        context.ui.toast.show({
          message: `Auto-approve failed: ${String(error)}`,
          variant: "error",
        })
      }
    })

    // "/auto" toggles the flag; also reachable from the command palette.
    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "auto-approve.toggle",
          title: "Toggle auto-approve (runtime)",
          group: "Auto",
          palette: true,
          slash: { name: "auto" },
          run: () => {
            const next = !state.enabled
            update((draft) => {
              draft.enabled = next
            })
            context.ui.toast.show({
              message: `Auto-approve ${next ? "ON" : "OFF"}`,
              variant: next ? "success" : "warning",
            })
          },
        },
      ],
    }))

    // Persistent indicator: shown in the prompt footer while enabled.
    context.ui.slot({
      append: "prompt.footer.status",
      render: () => (state.enabled ? <text fg={context.theme.text.feedback.warning.base}>{"\u26A1AUTO"}</text> : null),
    })
  },
})
