defmodule Lockspire.Web.Admin.Controls do
  @moduledoc false

  # Embedded with the admin shell, so adopters do not need to register a host hook.
  @javascript ~S"""
  (() => {
    const parseValues = (value) => [...new Set(String(value || "").split(/[,\r\n]+/).map(item => item.trim()).filter(Boolean))];
    const addValues = (values, text) => [...new Set([...values, ...parseValues(text)])];
    const valueEntryPlaceholder = (values, suggestions) => !values.length ? "Add a value…"
      : suggestions.length && suggestions.every(value => values.includes(value)) ? "Add a custom value…"
      : "Add another…";
    const acknowledgePending = (pending, revision) => pending.filter(edit => edit > revision);
    if (typeof module !== "undefined") module.exports = { parseValues, addValues, acknowledgePending, valueEntryPlaceholder };
    if (typeof document === "undefined" || document.documentElement.dataset.lockspireControlsReady) return;
    document.documentElement.dataset.lockspireControlsReady = "true";

    const states = new WeakMap();
    const requests = new WeakMap();
    let scheduled = false;
    let sectionNavigation = null;
    const nav = () => document.querySelector("[data-lockspire-preserve-scroll]");
    const rememberAnchor = () => {
      const current = nav();
      if (!current || sectionNavigation) return;
      history.replaceState({ ...history.state, lockspirePolicyNavTop: current.getBoundingClientRect().top }, "", location.href);
    };
    const sizeWorkspace = () => {
      const current = nav();
      const body = current?.closest(".lockspire-admin-body");
      if (!body) return;
      const offset = current.getBoundingClientRect().bottom - body.getBoundingClientRect().top;
      const minimum = Math.ceil(window.innerHeight + offset) + "px";
      if (body.style.minBlockSize !== minimum) body.style.minBlockSize = minimum;
    };
    document.addEventListener("click", event => {
      sectionNavigation = null;
      const link = event.target.closest("[data-lockspire-preserve-scroll] a[data-phx-link]");
      if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      rememberAnchor();
      sectionNavigation = { href: link.href, top: nav().getBoundingClientRect().top, keyboard: event.detail === 0 };
    }, true);
    window.addEventListener("popstate", event => {
      const top = event.state?.lockspirePolicyNavTop;
      sectionNavigation = typeof top === "number" ? { href: location.href, top, keyboard: false } : null;
    }, true);
    window.addEventListener("phx:page-loading-stop", () => {
      const pending = sectionNavigation;
      if (!pending || location.href !== pending.href) return;
      sectionNavigation = null;
      requestAnimationFrame(() => {
        sizeWorkspace();
        const current = nav();
        if (!current) return;
        window.scrollTo({ top: Math.max(0, scrollY + current.getBoundingClientRect().top - pending.top), behavior: "instant" });
        if (pending.keyboard) current.querySelector('a[aria-current="page"]')?.focus({ preventScroll: true });
        rememberAnchor();
      });
    });
    const revealCurrentSection = () => {
      const current = nav();
      const link = current?.querySelector('a[aria-current="page"]');
      if (!link || current.scrollWidth <= current.clientWidth) return;
      const start = link.offsetLeft - current.offsetLeft;
      if (start < current.scrollLeft || start + link.offsetWidth > current.scrollLeft + current.clientWidth) {
        current.scrollLeft = start - (current.clientWidth - link.offsetWidth) / 2;
      }
    };
    window.addEventListener("phx:page-loading-stop", () => requestAnimationFrame(revealCurrentSection));
    let scrollTimer;
    window.addEventListener("scroll", () => {
      clearTimeout(scrollTimer);
      scrollTimer = setTimeout(rememberAnchor, 150);
    }, { passive: true });
    window.addEventListener("wheel", () => { sectionNavigation = null; }, { passive: true });
    window.addEventListener("touchstart", () => { sectionNavigation = null; }, { passive: true });
    const fieldsIn = form => [...form.querySelectorAll("[data-lockspire-multi-value], [data-lockspire-checkbox-group]")];
    window.addEventListener("phx:page-loading-start", event => {
      if (event.detail.kind !== "element") return;
      const target = event.detail.target;
      const form = target.form || target.closest("form");
      if (!form) return;
      const queue = requests.get(target) || [];
      queue.push(fieldsIn(form).map(field => states.get(field)).filter(Boolean).map(state => ({ state, revision: state.revision })));
      requests.set(target, queue);
    });
    window.addEventListener("phx:page-loading-stop", event => {
      if (event.detail.kind !== "element") return;
      const queue = requests.get(event.detail.target);
      const snapshot = queue?.shift();
      snapshot?.forEach(({ state, revision }) => {
        state.pending = acknowledgePending(state.pending, revision);
      });
      schedule();
    });

    const initChoices = field => {
      const source = field.querySelector("[data-lockspire-values-source]");
      const options = field.querySelector("[data-lockspire-checkbox-options]");
      const state = { source, values: parseValues(source.value), revision: 0, pending: [], serverValue: field.dataset.values };
      state.refresh = () => {
        state.values.forEach(value => {
          if ([...options.querySelectorAll("input")].some(input => input.value === value)) return;
          const label = document.createElement("label");
          label.className = "lockspire-admin-radio-choice";
          const input = document.createElement("input");
          input.type = "checkbox";
          input.value = value;
          const text = document.createElement("span");
          text.textContent = value;
          label.append(input, text);
          options.append(label);
        });
        options.querySelectorAll("input").forEach(input => {
          input.checked = state.values.includes(input.value);
          input.setAttribute("aria-invalid", field.dataset.invalid);
          input.setAttribute("aria-describedby", field.dataset.describedBy);
        });
        source.value = state.values.join(", ");
      };
      states.set(field, state);
      field.addEventListener("input", event => {
        if (event.target.type === "checkbox") event.stopPropagation();
      }, true);
      field.addEventListener("change", event => {
        if (event.target.type !== "checkbox") return;
        event.stopPropagation();
        const checked = [...options.querySelectorAll("input:checked")].map(input => input.value);
        state.values = state.values.filter(value => checked.includes(value));
        state.values = [...new Set([...state.values, ...checked])];
        state.refresh();
        state.pending.push(++state.revision);
        source.dispatchEvent(new Event("input", { bubbles: true }));
      });
      state.refresh();
    };

    const init = field => {
      const source = field.querySelector("[data-lockspire-values-source]");
      if (!source) return;
      const id = source.id;
      const required = source.required;
      source.id = id + "-source";
      source.type = "hidden";
      source.required = false;
      const entry = document.createElement("input");
      entry.id = id;
      entry.type = "text";
      entry.autocomplete = "off";
      entry.placeholder = "Add a value…";
      entry.disabled = source.disabled;
      entry.dataset.lockspireValuesEntry = "";
      const list = document.createElement("ul");
      list.className = "lockspire-admin-multi-value__tokens";
      list.setAttribute("aria-label", "Selected values");
      const menu = document.createElement("div");
      menu.id = id + "-suggestions";
      menu.className = "lockspire-admin-multi-value__suggestions";
      menu.setAttribute("role", "listbox");
      menu.setAttribute("aria-label", "Suggested values");
      menu.hidden = true;
      const status = field.querySelector("[data-lockspire-values-status]");
      const state = { values: parseValues(source.value), entry, source, list, menu, required, active: -1, matches: [], revision: 0, pending: [], serverValue: field.dataset.values };
      states.set(field, state);
      field.append(list, entry, menu);
      field.classList.add("lockspire-admin-multi-value--enhanced");
      const suggestions = JSON.parse(field.dataset.suggestions || "[]");
      if (suggestions.length) {
        entry.setAttribute("role", "combobox");
        entry.setAttribute("aria-autocomplete", "list");
        entry.setAttribute("aria-controls", menu.id);
        entry.setAttribute("aria-expanded", "false");
      }
      const close = () => {
        menu.hidden = true;
        state.active = -1;
        entry.removeAttribute("aria-activedescendant");
        if (suggestions.length) entry.setAttribute("aria-expanded", "false");
      };
      const showSuggestions = () => {
        state.matches = suggestions.filter(value => !state.values.includes(value) && value.toLowerCase().includes(entry.value.toLowerCase())).slice(0, 8);
        state.active = -1;
        menu.replaceChildren();
        state.matches.forEach((value, index) => {
          const option = document.createElement("button");
          option.type = "button";
          option.tabIndex = -1;
          option.id = menu.id + "-" + index;
          option.setAttribute("role", "option");
          option.setAttribute("aria-selected", "false");
          option.textContent = value;
          option.addEventListener("mousedown", event => event.preventDefault());
          option.addEventListener("click", () => { commit(value); entry.focus(); });
          menu.append(option);
        });
        menu.hidden = state.matches.length === 0;
        entry.removeAttribute("aria-activedescendant");
        if (suggestions.length) entry.setAttribute("aria-expanded", String(!menu.hidden));
      };
      const render = () => {
        list.replaceChildren();
        state.values.forEach((value, index) => {
          const token = document.createElement("li");
          const text = document.createElement("span");
          text.textContent = value;
          const remove = document.createElement("button");
          remove.type = "button";
          remove.disabled = source.disabled;
          remove.addEventListener("mousedown", event => event.preventDefault());
          remove.setAttribute("aria-label", "Remove " + value);
          // Draw the same small cross as other admin controls; token text is never HTML.
          remove.innerHTML = '<svg aria-hidden="true" viewBox="0 0 24 24" fill="none"><path d="m6 6 12 12M18 6 6 18" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/></svg>';
          remove.addEventListener("click", () => {
            state.values.splice(index, 1);
            render();
            publish();
            status.textContent = value + " removed.";
            (list.querySelectorAll("button")[index] || entry).focus();
          });
          remove.addEventListener("keydown", event => {
            if (!["ArrowLeft", "ArrowRight"].includes(event.key)) return;
            event.preventDefault();
            (list.querySelectorAll("button")[index + (event.key === "ArrowLeft" ? -1 : 1)] || entry).focus();
          });
          token.append(text, remove);
          list.append(token);
        });
        source.value = state.values.join(", ");
        entry.required = required && !state.values.length;
        entry.placeholder = valueEntryPlaceholder(state.values, suggestions);
      };
      const publish = () => {
        state.pending.push(++state.revision);
        source.dispatchEvent(new Event("input", { bubbles: true }));
      };
      const commit = (text = entry.value, notify = true) => {
        const prior = state.values.length;
        state.values = addValues(state.values, text);
        entry.value = "";
        render();
        close();
        const added = state.values.length - prior;
        if (text.trim()) status.textContent = !added ? "Already added." : added === 1 ? "Value added." : added + " values added.";
        if (notify && state.values.length !== prior) publish();
      };
      state.commit = commit;
      state.refresh = render;
      field.addEventListener("click", event => {
        if (event.target === field || event.target === list) {
          entry.focus();
          showSuggestions();
        }
      });
      entry.addEventListener("focus", showSuggestions);
      entry.addEventListener("click", showSuggestions);
      entry.addEventListener("input", event => {
        event.stopPropagation();
        if (event.isComposing) return;
        if (entry.value.includes(",")) commit();
        else showSuggestions();
      });
      entry.addEventListener("keydown", event => {
        if (event.isComposing) return;
        if (event.key === "Enter" || event.key === ",") {
          event.preventDefault();
          commit(state.active >= 0 ? state.matches[state.active] : entry.value);
        } else if (event.key === "Escape") {
          event.preventDefault();
          close();
        } else if (event.key === "Backspace" && !entry.value && state.values.length) {
          event.preventDefault();
          const removed = state.values.pop();
          render();
          publish();
          status.textContent = removed + " removed.";
        } else if (event.key === "ArrowLeft" && !entry.value) {
          list.querySelector("li:last-child button")?.focus();
        } else if (["ArrowDown", "ArrowUp"].includes(event.key) && suggestions.length) {
          event.preventDefault();
          if (menu.hidden) showSuggestions();
          if (!state.matches.length) return;
          state.active = state.active < 0
            ? (event.key === "ArrowDown" ? 0 : state.matches.length - 1)
            : (state.active + (event.key === "ArrowDown" ? 1 : -1) + state.matches.length) % state.matches.length;
          [...menu.children].forEach((option, index) => option.setAttribute("aria-selected", String(index === state.active)));
          entry.setAttribute("aria-activedescendant", menu.children[state.active].id);
        }
      });
      entry.addEventListener("paste", event => {
        const text = event.clipboardData.getData("text");
        if (!/[,\r\n]/.test(text)) return;
        event.preventDefault();
        commit(entry.value.slice(0, entry.selectionStart) + text + entry.value.slice(entry.selectionEnd));
      });
      entry.addEventListener("blur", event => {
        if (menu.contains(event.relatedTarget)) return;
        const nextLabel = list.contains(event.relatedTarget) ? event.relatedTarget.getAttribute("aria-label") : null;
        if (entry.value.trim()) commit();
        if (nextLabel && !event.relatedTarget.isConnected) {
          [...list.querySelectorAll("button")].find(button => button.getAttribute("aria-label") === nextLabel)?.focus({ preventScroll: true });
        }
        close();
      });
      render();
    };
    const scan = () => {
      scheduled = false;
      sizeWorkspace();
      document.querySelectorAll("[data-lockspire-multi-value], [data-lockspire-checkbox-group]").forEach(field => {
        if (!states.has(field)) {
          if (field.hasAttribute("data-lockspire-checkbox-group")) initChoices(field);
          else init(field);
        }
        const state = states.get(field);
        if (!state) return;
        if (state.entry) {
          state.entry.setAttribute("aria-invalid", field.dataset.invalid);
          state.entry.setAttribute("aria-describedby", field.dataset.describedBy);
        } else state.refresh();
        if (state.pending.length) return;
        if (state.serverValue !== field.dataset.values) {
          state.serverValue = field.dataset.values;
          const values = parseValues(state.serverValue);
          // A preview echo must not wipe the draft or steal focus.
          if (values.join(", ") !== state.source.value) {
            state.values = values;
            state.refresh();
          }
        }
      });
    };
    const schedule = () => {
      if (!scheduled) { scheduled = true; requestAnimationFrame(scan); }
    };
    new MutationObserver(schedule).observe(document.documentElement, {
      childList: true, subtree: true, attributes: true,
      attributeFilter: ["data-values", "data-invalid", "data-described-by"]
    });
    window.addEventListener("resize", schedule);
    document.addEventListener("submit", event => {
      const fields = fieldsIn(event.target).filter(field => states.has(field));
      if (!fields.length) return;
      fields.forEach(field => {
        const state = states.get(field);
        if (state?.entry?.value.trim()) state.commit(undefined, false);
      });
      if (!event.target.noValidate && !event.submitter?.formNoValidate && !event.target.checkValidity()) {
        event.preventDefault();
        event.stopImmediatePropagation();
        event.target.reportValidity();
      }
    }, true);
    schedule();
  })();
  """

  def javascript, do: @javascript
end
