package space.mamba.mybatis;

/**
 * @author mamba
 * @date 21/06/2018
 * <pre>
 *
 * </pre>
 */
public class Demo {
    private Integer id;
    private String str;

    private Long sId;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getStr() {
        return str;
    }

    public void setStr(String str) {
        this.str = str;
    }


    public Long getsId() {
        return sId;
    }

    public void setsId(Long sId) {
        this.sId = sId;
    }

    @Override
    public String toString() {
        return "Demo{" +
                "id=" + id +
                ", str='" + str + '\'' +
                ", sId=" + sId +
                '}';
    }
}
