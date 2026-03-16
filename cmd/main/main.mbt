///|
async fn main {
  // exec: run a shell command and collect output
  let result = @subprocess.exec("echo 'Hello from subprocess'")
  println("exec: " + result.stdout.trim(chars="\n").to_string())

  // exec_file: run an executable directly
  let result2 = @subprocess.exec_file("uname", args=["-s"])
  println("exec_file: " + result2.stdout.trim(chars="\n").to_string())

  // spawn: streaming I/O with pipes
  @async.with_task_group(async fn(group) {
    let child = @subprocess.spawn(
      group,
      "cat",
      pipe_stdin=true,
      pipe_stdout=true,
    )
    child.stdin.unwrap().write("Hello from parent\n")
    child.stdin.unwrap().close()
    let data = child.stdout.unwrap().read_all()
    println("spawn: " + data.text().trim(chars="\n").to_string())
    let _ = child.wait()
    group.return_immediately(())
  })

  // managed: process pool with zombie prevention
  let pm = @managed.ProcessManager::new()
  let r = pm.exec("echo managed")
  println("managed: " + r.stdout.trim(chars="\n").to_string())

  // ipc/socket: IPC over AF_UNIX socket
  let sock_path = "/tmp/subprocess_example.sock"
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  client.send("hello from client")
  let msg = conn.recv()
  println("ipc: " + msg.unwrap())
  client.close()
  conn.close()
  server.close()
}
