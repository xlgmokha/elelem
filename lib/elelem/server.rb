# frozen_string_literal: true

module Elelem
  class Server
    def initialize(agent, port: 4567, address: "0.0.0.0")
      @agent = agent
      @port = port
      @address = address
      @terminal = agent.terminal
    end

    def start
      server = WEBrick::HTTPServer.new(
        Port: @port,
        BindAddress: @address,
        Logger: WEBrick::Log.new(File::NULL),
        AccessLog: []
      )
      server.mount_proc("/", &method(:index))
      server.mount_proc("/events", &method(:events))
      server.mount_proc("/message", &method(:message))
      server.mount_proc("/answer", &method(:answer))

      trap("INT") { server.shutdown }
      $stdout.puts "elelem v#{VERSION} listening on http://#{@address}:#{@port}"
      server.start
    end

    private

    def index(_req, res)
      res.content_type = "text/html; charset=utf-8"
      res.body = INDEX
    end

    def events(_req, res)
      res.content_type = "text/event-stream"
      res["Cache-Control"] = "no-cache"
      res.chunked = true
      res.body = ->(out) { stream(out) }
    end

    def stream(out)
      events = @terminal.subscribe
      loop do
        out.write("data: #{JSON.dump(events.pop)}\n\n")
      end
    rescue IOError, Errno::EPIPE, Errno::ECONNRESET
      nil
    ensure
      @terminal.unsubscribe(events)
    end

    def message(req, res)
      text = JSON.parse(req.body)["text"].to_s
      Thread.new do
        @agent.turn(text)
      rescue => e
        @terminal.say("Error: #{e.message}")
      ensure
        @terminal.done
      end
      res.status = 204
    end

    def answer(req, res)
      @terminal.answer(JSON.parse(req.body)["text"].to_s)
      res.status = 204
    end

    INDEX = <<~HTML
      <!doctype html>
      <html lang="en">
      <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
      <title>elelem</title>
      <style>
        :root { color-scheme: dark; }
        * { box-sizing: border-box; }
        body {
          margin: 0; height: 100dvh; display: flex; flex-direction: column;
          background: #16161a; color: #e6e6e6;
          font: 16px/1.55 ui-sans-serif, system-ui, -apple-system, sans-serif;
        }
        #log { flex: 1; overflow-y: auto; padding: 1rem; -webkit-overflow-scrolling: touch; }
        .msg { max-width: 46rem; margin: 0 auto 1rem; padding: .65rem .85rem; border-radius: .6rem; }
        .user { background: #2d3a4f; }
        .assistant { background: #22222a; }
        .thinking { opacity: .55; font-style: italic; white-space: pre-wrap; }
        .msg pre {
          background: #0d0d10; padding: .7rem; border-radius: .4rem;
          overflow-x: auto; font-size: .875rem;
        }
        .msg code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
        .prompt { max-width: 46rem; margin: 0 auto 1rem; padding: .85rem; border-radius: .6rem; background: #4a3a1e; }
        .prompt button {
          font-size: 1rem; padding: .7rem 1.4rem; margin: .5rem .5rem 0 0;
          border: 0; border-radius: .5rem; color: #fff; touch-action: manipulation;
        }
        .allow { background: #2f7d4f; }
        .deny { background: #8c3535; }
        form { display: flex; gap: .5rem; padding: .75rem; padding-bottom: max(.75rem, env(safe-area-inset-bottom));
               border-top: 1px solid #2c2c33; background: #1b1b20; }
        textarea {
          flex: 1; resize: none; font: inherit; padding: .6rem; border-radius: .5rem;
          border: 1px solid #35353d; background: #101014; color: inherit;
        }
        button.send { font-size: 1rem; padding: .6rem 1.2rem; border: 0; border-radius: .5rem; background: #3b6ea5; color: #fff; }
      </style>
      </head>
      <body>
      <div id="log"></div>
      <form id="composer">
        <textarea id="input" rows="1" placeholder="Message elelem…" autocapitalize="sentences"></textarea>
        <button class="send" type="submit">Send</button>
      </form>
      <script>
      const log = document.getElementById("log");
      const input = document.getElementById("input");
      let current = null;

      const atBottom = () => log.scrollHeight - log.scrollTop - log.clientHeight < 80;
      const scroll = (was) => { if (was) log.scrollTop = log.scrollHeight; };

      function escape(text) {
        return text.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c]);
      }

      function render(text) {
        return escape(text)
          .replace(/```(\\w*)\\n([\\s\\S]*?)```/g, (_m, _lang, code) => "<pre><code>" + code + "</code></pre>")
          .replace(/`([^`\\n]+)`/g, "<code>$1</code>")
          .replace(/\\*\\*([^*]+)\\*\\*/g, "<strong>$1</strong>")
          .replace(/\\n/g, "<br>");
      }

      function bubble(cls) {
        const was = atBottom();
        const el = document.createElement("div");
        el.className = "msg " + cls;
        log.appendChild(el);
        scroll(was);
        return el;
      }

      function append(cls, text) {
        if (!current || current.dataset.cls !== cls) {
          current = bubble(cls);
          current.dataset.cls = cls;
          current.dataset.raw = "";
        }
        const was = atBottom();
        current.dataset.raw += text;
        current.innerHTML = render(current.dataset.raw);
        scroll(was);
      }

      function askPermission(text) {
        current = null;
        const was = atBottom();
        const el = document.createElement("div");
        el.className = "prompt";
        el.innerHTML = "<div>" + escape(text) + "</div>";
        const respond = (answer) => {
          el.querySelectorAll("button").forEach((b) => b.remove());
          el.insertAdjacentHTML("beforeend", "<div><em>" + answer + "</em></div>");
          fetch("/answer", { method: "POST", body: JSON.stringify({ text: answer }) });
        };
        const allow = document.createElement("button");
        allow.className = "allow";
        allow.textContent = "Allow";
        allow.onclick = () => respond("y");
        const deny = document.createElement("button");
        deny.className = "deny";
        deny.textContent = "Deny";
        deny.onclick = () => respond("n");
        el.append(allow, deny);
        log.appendChild(el);
        scroll(was);
      }

      new EventSource("/events").onmessage = (e) => {
        const event = JSON.parse(e.data);
        if (event.type === "content") append("assistant", event.text);
        else if (event.type === "thinking") append("thinking", event.text);
        else if (event.type === "prompt") askPermission(event.text);
        else if (event.type === "done") current = null;
      };

      document.getElementById("composer").onsubmit = (e) => {
        e.preventDefault();
        const text = input.value.trim();
        if (!text) return;
        append("user", text);
        current = null;
        input.value = "";
        fetch("/message", { method: "POST", body: JSON.stringify({ text: text }) });
      };

      input.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault();
          document.getElementById("composer").requestSubmit();
        }
      });

      input.addEventListener("input", () => {
        input.style.height = "auto";
        input.style.height = Math.min(input.scrollHeight, 160) + "px";
      });
      </script>
      </body>
      </html>
    HTML
  end
end
