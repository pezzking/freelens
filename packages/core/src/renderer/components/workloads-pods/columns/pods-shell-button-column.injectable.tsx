/**
 * Copyright (c) Freelens Authors. All rights reserved.
 * Copyright (c) OpenLens Authors. All rights reserved.
 * Licensed under MIT License. See LICENSE in root directory for more information.
 */

import { Icon } from "@freelensapp/icon";
import { podListLayoutColumnInjectionToken } from "@freelensapp/list-layout";
import { getInjectable } from "@ogre-tools/injectable";
import { withInjectables } from "@ogre-tools/injectable-react";
import os from "os";
import React from "react";
import { v4 as uuidv4 } from "uuid";
import { App } from "../../../../extensions/common-api";
import createTerminalTabInjectable from "../../dock/terminal/create-terminal-tab.injectable";
import sendCommandInjectable, { type SendCommand } from "../../dock/terminal/send-command.injectable";
import { COLUMN_PRIORITY } from "./column-priority";

import type { Pod } from "@freelensapp/kube-object";
import type { DockTabCreateSpecific } from "../../dock/dock/store";

const columnId = "shell";

interface Dependencies {
  createTerminalTab: (tabParams: DockTabCreateSpecific) => void;
  sendCommand: SendCommand;
}

interface ShellButtonProps {
  pod: Pod;
}

const NonInjectableShellButton: React.FC<ShellButtonProps & Dependencies> = ({
  pod,
  createTerminalTab,
  sendCommand,
}) => {
  const handleClick = (event: React.MouseEvent) => {
    event.stopPropagation();

    const containers = pod.getRunningContainers();

    if (containers.length === 0) {
      return;
    }

    const container = containers[0];
    const kubectlPath = App.Preferences.getKubectlPath() || "kubectl";
    const commandParts = [kubectlPath, "exec", "-i", "-t", "-n", pod.getNs(), pod.getName()];

    if (os.platform() !== "win32") {
      commandParts.unshift("exec");
    }

    if (container.name) {
      commandParts.push("-c", container.name);
    }

    commandParts.push("--");

    if (pod.getSelectedNodeOs() === "windows") {
      commandParts.push("powershell");
    } else {
      commandParts.push('sh -c "clear; (bash || ash || sh)"');
    }

    const shellId = uuidv4();

    createTerminalTab({
      title: `Pod: ${pod.getName()} (namespace: ${pod.getNs()})`,
      id: shellId,
    });

    sendCommand(commandParts.join(" "), {
      enter: true,
      tabId: shellId,
    });
  };

  return (
    <Icon svg="ssh" tooltip="Pod Shell" interactive onClick={handleClick} style={{ cursor: "pointer" }} />
  );
};

const ShellButton = withInjectables<Dependencies, ShellButtonProps>(NonInjectableShellButton, {
  getProps: (di, props) => ({
    ...props,
    createTerminalTab: di.inject(createTerminalTabInjectable),
    sendCommand: di.inject(sendCommandInjectable),
  }),
});

export const podsShellButtonColumnInjectable = getInjectable({
  id: "pods-shell-button-column",
  instantiate: () => ({
    id: columnId,
    kind: "Pod",
    apiVersion: "v1",
    priority: COLUMN_PRIORITY.SHELL,
    content: (pod: Pod) => <ShellButton pod={pod} />,
    header: { title: <Icon svg="ssh" />, className: "shell", id: columnId },
  }),
  injectionToken: podListLayoutColumnInjectionToken,
});
