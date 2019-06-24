package space.pankui.redis_client;

import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;

import static space.pankui.constant.RedisCommandConstant.CHARSET;

/**
 * @author pankui
 * @date 2019-06-24
 * <pre>
 *
 * </pre>
 */
@Slf4j
public class RedisClient {

    private static String host = "127.0.0.1";
    private static final int port = 6379;


    OutputStream outputStream = null;
    InputStream inputStream = null;

    public static void main(String[] args) throws Exception {
        RedisClient redisClient = new RedisClient();
        redisClient.connect();
        redisClient.selectDbIndex(0);

        redisClient.command(null);

        redisClient.command("set key 1");

        redisClient.command("incr incrKey");

        redisClient.command("notExistCommand");

        redisClient.command("del myList");
        redisClient.command("LPUSH myList java python goland php");
        redisClient.command("LRANGE myList");


    }

    public void connect() throws IOException {

        Socket socket = new Socket();
        socket.setReuseAddress(true);
        socket.setKeepAlive(true);
        socket.setTcpNoDelay(true);
        socket.setSoLinger(true, 0);
        socket.connect(new InetSocketAddress(host, port), 10 * 1000);
        socket.setSoTimeout(10 * 1000);
        outputStream = socket.getOutputStream();
        inputStream = socket.getInputStream();

    }

    public void auth() {
        // auth password
        /**
         * String authCmd = "AUTH " + password;
         * byte[] authCmdBytes = RedisCommandParser.parse(authCmd);
         * outputStream.write(authCmdBytes);
         * outputStream.flush();
         * byte[] bytes = new byte[102400];
         * int length = inputStream.read(bytes);
         * String authResult = new String(bytes, 0, length, charset);
         * logger.info(authResult);
         */

    }

    public void selectDbIndex(int dbIndex) throws IOException {
        //SELECT dbIndex
        String selectCmd = "SELECT " + dbIndex;
        byte[] selectCmdBytes = RedisCommandParser.parse(selectCmd);
        outputStream.write(selectCmdBytes);
        outputStream.flush();
        byte[] bytes = new byte[102400];
        int length = inputStream.read(bytes);
        String selectResult = new String(bytes, 0, length, CHARSET);
        System.out.println(selectResult);
    }

    public void command(String command) throws IOException {
        byte[] commandBytes = RedisCommandParser.parse(command);
        outputStream.write(commandBytes);
        outputStream.flush();
        byte[] bytes = new byte[102400];
        int length = inputStream.read(bytes);
        String result = new String(bytes, 0, length, CHARSET);
        System.out.println(String.format("\ncommand:\n%s\nresult:\n%s", new String(commandBytes, CHARSET), result));
    }
}

