package space.pankui.mybatis;

import org.apache.ibatis.annotations.Param;

/**
 * @author pankui
 * @date 21/06/2018
 * <pre>
 *
 * </pre>
 */
public interface DemoMapper {


    Demo getDemoById(Integer id);

    /**
     *
     * 如果这里没有 @Param 注解，而xml 里面有 OGNL 表达式判断str
     *   <if test="str !=null"> ,那么就会报错
     *    There is no getter for property named 'str' in 'class java.lang.String
     *
     *    但是，但是 如果str 换成javaBean 就没有问题了呢？？？？
     * */
    Demo getDemoByStr(String str);


    Demo getDemoByStrSId(@Param("demo")Demo demo);

}
