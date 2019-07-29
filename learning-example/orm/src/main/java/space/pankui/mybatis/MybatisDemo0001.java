package space.pankui.mybatis;

import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.session.defaults.DefaultSqlSessionFactory;
import org.junit.Test;


import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

/**
 * @author pankui
 * @date 21/06/2018
 * <pre>
 *
 * </pre>
 */
public class MybatisDemo0001 {

    static SqlSession sqlSession;

    static {
        String resource = "mybatis-config.xml";
        InputStream inputStream = null;
        try {
            inputStream = Resources.getResourceAsStream(resource);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // 加载配置文件，创建 sqlSessionFactory 对象
        SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);

        // 创建SqlSession 对象
        sqlSession = sqlSessionFactory.openSession();
    }


    public static void main(String[] args) throws IOException {

        try {

            Map<String, Object> paramMap = new HashMap<>(1);
            paramMap.put("id", 1);


            Demo demo = sqlSession.selectOne("space.pankui.mybatis.DemoMapper.getDemoById", paramMap);

            DemoMapper demoMapper = sqlSession.getMapper(DemoMapper.class);

            Demo demo2 = demoMapper.getDemoById(1);


            //输出
            System.out.println(demo);


            System.out.println(demo2);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            sqlSession.close();
        }
        //

    }


    @Test
    public void testMybatisParam() {

        DemoMapper demoMapper = sqlSession.getMapper(DemoMapper.class);
        Demo demo2 = demoMapper.getDemoByStr("1a1s3df3");
        System.out.println(demo2);

        sqlSession.close();
    }

    @Test
    public void testMybatisParam2() {

        Demo demo = new Demo();
        demo.setsId(333L);

        DemoMapper demoMapper = sqlSession.getMapper(DemoMapper.class);
        Demo demo2 = demoMapper.getDemoByStrSId(demo);
        System.out.println(demo2);

        Demo demo3 = demoMapper.getDemoByStr("1a1s3df3");
        System.out.println(demo3);

        sqlSession.close();
    }

}
