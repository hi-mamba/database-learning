package space.pankui.redis_client;

import org.apache.commons.lang3.StringUtils;
import space.pankui.constant.RESPConstant;
import space.pankui.constant.RedisCommandConstant;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.security.InvalidParameterException;

import static space.pankui.constant.RedisCommandConstant.CHARSET;

/**
 * @author pankui
 * @date 2019-06-24
 * <pre>
 *
 *     https://www.dubby.cn/detail.html?id=9121
 *
 *     自己动手写一个Redis客户端
 * </pre>
 */
public class RedisCommandParser {

    private static final byte[] Digit = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

    /**
     * redis 参数
     */
    public static byte[] parse(String command) throws IOException {
        if (StringUtils.isBlank(command)) {
            command = RedisCommandConstant.PING;
        }

        command = command.trim();

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        stream.write(RESPConstant.ASTERISK_TYPE);

        String[] cmdSplit = command.split(" ");
        int length = 0;
        for (String str : cmdSplit) {
            if (!StringUtils.isEmpty(str)) {
                length++;
            }
        }

        // 求 空格 隔开 长度 比如  set key test  长度为3， incr key1 长度为2
        // 客户端和服务器发送的命令或数据一律以 \r\n （CRLF）结尾。
        stream.write(intToByte(length));
        stream.write('\r');
        stream.write('\n');

        for (String str : cmdSplit) {
            if (StringUtils.isEmpty(str)) {
                continue;
            }

            // 第一字节为 `"$"` 符号
            stream.write(RESPConstant.DOLLAR_BYTE);
            stream.write(intToByte(str.getBytes(CHARSET).length));
            stream.write('\r');
            stream.write('\n');
            stream.write(str.getBytes(CHARSET));
            stream.write('\r');
            stream.write('\n');
        }

        return stream.toByteArray();
    }

    private static byte[] intToByte(int i) {
        if (i < 0) {
            return new byte[0];
        }
        if (i < 10) {
            byte[] bytes = new byte[1];
            bytes[0] = Digit[i];
            return bytes;
        }

        if (i < 100) {
            byte[] bytes = new byte[2];
            bytes[0] = Digit[i / 10];
            bytes[1] = Digit[i / 10];
            return bytes;
        }

        throw new InvalidParameterException("redis command too long");
    }

}
