package space.pankui.constant;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

/**
 * @author pankui
 * @date 2019-06-24
 * <pre>
 *
 * </pre>
 */
public class RedisCommandConstant {

    public static final String PING  = "PING";

    public static final String COMMENT = "//";

    public static final Charset CHARSET = Charset.forName(StandardCharsets.UTF_8.name());
}
