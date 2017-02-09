---
title: spring AOP 基础


date: 2017-02-08 19:54:53
categories:
 - java
 - spring
 - aop

tags:
 - aop
 - proxy

author: jeffor
---

## 切面编程

**面向切面编程 AOP(Aspect-Oriented Programming)** 是从一个不同的编程方式角度对 **面向对象编程 OOP** 的完善。在切面编程中，切面是一个关键元素，正如面向对象编程中对象是一个核心元素。切面的功能是使一些跨越对象的逻辑模块化，如 **事务管理**。

<!-- more -->

---

## 一. 基本概念

**让我们先了解一下spring AOP 的一些基础概念:**

1. aspect(切面): 跨越多个类的共同逻辑，即从多个类中抽出的相同执行模块，如事务管理模块。此处 `aspcet` 只是概念性关键字， 下面介绍的其他关键字都属于切面的范畴。
2. join point(连接点): 程序中允许切面执行的时机，如方法执行时，异常处理时。需要注意的是`spring只支持方法连接点`。
3. advice(通知): advice 是切面在切点处的执行逻辑，其按照其执行方式可以分成`before advice`, `after advice`, `after throwing advice`, `after returning advice`, `around advice`五种。
4. pointcut(切点): pointcut 定义了切面与连接点的匹配规则。`advice` 会根据 `pointcut` 定义的规则去匹配相应的 `joint point`, 并最终执行 `advice` 定义的切面逻辑。
5. introduction(引入): 这应该可以理解成切面编程中一个特殊的功能: 向一个类中引入外部接口和属性，简单地说就是扩展一个类对外暴露的接口。
6. target object(目标对象): 被切面切入代理逻辑的业务对象。
7. AOP proxy(切面代理对象): 框架为实现切面生成的动态代理对象。spring 动态代理对象可以分为`JDK dynamic proxy` 和 `CGLIB dynamic proxy`。
8. waving(织入): 指实现切面和目标类进行关联的行为过程，通常 `编译,加载,运行` 环节都可进行。`spring AOP 框架` 和 其他 `纯 java aop 框架` 一样只在运行时进行织入。

> 这些概念目前看来可能还不大直观，但是不用着急，在后面的样例中我们将逐一详细了解。到时候再回顾来看就肯定清晰了。

---

## 二. spring AOP 特点

这里让我们简单了解一下 spring AOP 的特点（相较其他 AOP 框架，如 [AspectJ](http://www.eclipse.org/aspectj/doc/released/progguide/) 而言）:

  - spring AOP 是一个纯java实现的AOP框架，因此只支持运行时进行切面织入;
  - spring 目前只支持 `方法级别的切点(method join point)`（field join point 实现 可以考虑使用 AspectJ 框架）;
  - spring AOP 并不以一个 尽善静美的AOP实现 作为目标，它希望推出一个能与 `spring IOC 框架` **整合** 的框架，使它们一起为企业级应用提供便捷的开发解决方案。
  - spring AOP 动态代理有两种实现形式: `JDK 原生动态代理` 和 `CGLIB 动态代理`。如果被代理的目标对象没有实现接口，`CGLIB 动态代理` 将被置为默认选择。

---

## 三. spring AOP 详解

**这里因为篇幅原因我只描述 spring 基于注解的 AOP 实现，spring 还支持基于 `xml schema` 配置的 AOP 实现，它们除了表现形式不同之外没什么其他区别。相比而言 注解形式 更清晰便捷。对 `xml schema` 配置形式感兴趣的小伙伴可以自己了解。**

### I. 使用 @AspectJ 注解声明切面

 `@AspectJ` 是 [Aspectj](http://www.eclipse.org/aspectj/doc/released/progguide/)框架支持的注解，通过引入 AspectJ Library 依赖, spring 将支持 AspectJ 中相关注解的解析，但是spring不会使用 AspectJ 中的编译和织入功能。

 引入 AspectJ Library 后， `@AspectJ` 注解将可以声明一个普通class为切面定义类。

1. maven 依赖引入样例如下:

 ```
	 <dependency>
	    <groupId>org.aspectj</groupId>
	    <artifactId>aspectjrt</artifactId>
	    <version>1.8.1</version>
	</dependency>
	
	
	<dependency>
	    <groupId>org.aspectj</groupId>
	    <artifactId>aspectjweaver</artifactId>
	    <version>1.8.1</version>
	</dependency>
 ```

2. 启用切面注解配置功能:

 spring 同时支持 `XML schema 切面配置` 和 `注解形式 切面配置`，若想启用注解方式，则需要在配置类(@Configuration 注释的类)上标注启用标签`@EnableAspectJAutoProxy`:

 ```
 @Configuration
 @EnableAspectJAutoProxy
 //@EnableAspectJAutoProxy(proxyTargetClass = true)             // 将代理方式选定为 CGLIB动态代理
 public class AppConfig { }
 ```

 > 注意 `@EnableAspectJAutoProxy` 可以指定 `proxyTargetClass` 属性，它用来控制是否只用 CGLIB 动态代理(默认为false, 即由spring框架自动选择代理逻辑)。

3. 声明切面:

 只需要在定义的切面类上加上 `@AspectJ` 注解即可将其标注为切面定义类:

 ```
 package org.xyz;
 import org.aspectj.lang.annotation.Aspect;
 @Aspect
 public class NotVeryUsefulAspect { }
 ```

 > 注意需要保证该类能够被配置类扫描到。

### II. pointcut 声明

 **`pointcut(切点)`用来定义 `advice(切面逻辑)` 和 `joint point(连接点)` 的匹配规则。在spring中，目前支持的连接点类型只有方法，因此可以认为 pointcut 只用来定义方法匹配规则就好了。**

 一个pointcut声明包含两个部分:
  - pointcut 方法声明，该方法没有任何参数，返回值为`void`;
  - pointcut 表达式, 使用 `@Pointcut` 注解定义;

 将pointcut样例如下:

 ```
￼ @Pointcut("execution(* transfer(..))")// the pointcut expression
  private void anyOldTransfer() {}// the pointcut signature
 ```

 > spring 的 pointcut 表达式就是复用 [`AspectJ 的pointcut表达式`](http://www.eclipse.org/aspectj/doc/released/adk15notebook/index.html)。


### III. spring 支持的 pointcut 表达式类型

 spring 只是支持了部分的 AspectJ pointcut 表达式规则，接下来我们逐一讲解其所支持的表达式规则。

####  execution 切点

 1. `execution` 切点是最常用的切点定义方式，其定义模式如下:

  ```
   execution(modifier-pattern? ret-type-pattern declaring-type-pattern?name-pattern(param-patterm) throw-pattern?)
  ```

|pattern|含义|是否必须定义|
| :--- | :--- | :--- |
|modifier-pattern|修饰符|否|
|ret-type-pattern|返回值类型定义|是|
|declaring-type-pattern|方法类定义|否|
|name-pattern|方法名称定义|是|
|param-patterm|参数列表定义|是|
|throw-pattern|异常类型定义|否|

> pattern 可以使用通配符定义: `*` 用来匹配所有模式，`.`用来表示类路径的分量符,`..`表示一个包及其子包下的任意类, `(..)`可以表示任意参数列表(表示包含零个或多个任意类型参数)

 2. `execution pointcut` 定义样例:

 ```
    /**
     * 任意public方法为切入点
     */
    @Pointcut("execution(public * *(..))")
    public void anyPublicOperation() {
    }

    /**
     * 任意set方法为切入点
     */
    @Pointcut("execution(* set*(..)")
    public void anySetOperation() {
    }

    /**
     * me.service 包下任意类的方法
     */
    @Pointcut("execution(* me.service.*(..)")
    public void anyServiceOperation() {
    }

    /**
     * me.service 包及其子包下任意类的方法
     */
    @Pointcut("execution(* me.service..*(..)")
    public void anyServiceBaseOperation() {
    }

    /**
     * 任意参数列表包含两个参数,且第二个参数类型是String类型的方法
     */
    @Pointcut("execution(* *(*, String)")
    public void anyStringParamInSecondPlaceOperation() {
    }
 ```

 > 样例中注释说明详尽，可以看出 `execution` 类型的pointcut基本可以满足任意场景的方法规则匹配。其他pointcut类型可以看做 execution 的部分限定规则。

#### within 切点

- within 切点只做了包和类型的限定:

 ```
    /**
     * 任意 me.service 包及其子包下各个类型的方法
     */
    @Pointcut("within(me.service..*)")
    public void withinOperation() {
    }
 ```

#### args 切点:

- args 切点只做了参数列表的限定:

 ```
    /**
     * 任意参数列表包含两个参数,且第二个参数类型是String类型的方法
     */
    @Pointcut("args(*, String)")
    public void argsOperation() {
    }
 ```

 > args 切点和 execution `execution(* *(*, String)` 切点还是不太相同的，execution 限定了目标方法的定义方式，而args则限定了目标方法在运行时是否传入 `(*, String)` 参数列表,是一种运行时限定。

#### this 切点:

- this 用来限定代理对象(proxy object)是否实现了某个接口:

 ```
	/**
     * 当一个代理对象实现了 me.Service 接口时才进行代理逻辑切入
     */
    @Pointcut("this(me.Service)")
    public void thisOperation() {
    }
 ```

#### target 切入:

- target 用来限定目标对象(target object)是否实现了某个接口:

 ```
   /**
     * 当一个目标对象实现了 me.Service 接口时才进行代理逻辑切入
     */
    @Pointcut("target(me.Service)")
    public void targetOperation() {
    }
 ```

 > 注意 `this 切入` 和 `target 切入` 类型的区别，this是对代理对象的限定规则，target是对目标对象的限定规则。
 > 需要了解的是 `JDK 动态代理` 在实现时，proxy对象实现了代理接口，而 `CGLIB 动态代理` 却并不一定。同时spring AOP 的 Introduction 功能将使代理对象继承新的接口，但目标对象（业务对象）却并未继承任何接口。

#### bean 切入:

- bean 用来限定对象的名称:

 ```
	/**
     * 任意以Service为后缀的bean
     */
    @Pointcut("bean(*Service)")
    public void beanOperation() {
    }
 ```

#### @target 切入:

- 匹配任意目标对象标注了特定标签:

 ```
    /**
     * 任意目标对象标注了Transaction注解的方法
     */
    @Pointcut("@target(me.Transaction)")
    public void targetAnnoationOperation() {
    }
 ```

#### @within 切入:

- 匹配任意拥有特定注解的类型:

 ```
	/**
     * 任意标注了Transaction注解的类的方法
     */
    @Pointcut("@within(me.Transaction)")
    public void withinAnnotationOperation() {
    }
 ```

#### @annotation 切入:

- 匹配任意标注了特定注解的方法:

 ```
	/**
     * 任意标注了Transaction注解的方法
     */
    @Pointcut("@annotation(me.Transaction)")
    public void annotationMethodOperation() {
    }
 ```

#### @args 切入:

- 匹配任意参数列表添加了特定注解注释的方法:

 ```
	/**
     * 任意参数列表只有一个参数,且参数标注了Transaction注解的方法
     */
    @Pointcut("@args(me.Transaction)")
    public void argsAnnotationMethodOperation() {
    }
 ```

#### 切点联立表达规则:

 **任意已经定义的切点都可以使用逻辑关联符号联立表达形成新的符合切点，可用的逻辑关联符号有 `&&`, `||`, `!`.**

 - 联立表达见样例如:

 ```
	/**
	 * spring 切面编程
	 */
	@Aspect
	public class AspectExample {
	
	    /**
	     * 切入任意 public 方法
	     */
	    @Pointcut("execution(public * *(..))")
	    private void anyPublicOperator() {
	    }
	
	
	    /**
	     * 定义在 me.trading 包下的任意方法
	     */
	    @Pointcut("within(me.trading..*)")
	    private void inTrading() {
	    }
	
	    /**
	     * 组合切点表达式,切入任意 me.trading 包下的 public 方法
	     */
	    @Pointcut("anyPublicOperator()||inTrading()")
	    private void publicTrading() {
	
	    }
	}
 ```

 > 在企业级应用开发中往往需要定义服务级别的公用切点，保证切点统一管理与可复用性。


### IV. Advice 声明

#### Advice的类型

如之前所述，`Advice` 定义了切面的切入逻辑，按照在`切点`吃的执行方式，可以分为以下五种类型:

 - before advice: 只在切点之前执行切面，该方式无法控制原业务方法的调用方式(除了抛出异常终止调用之外);
 - after returning: 在切点定义的方法正常结束之后执行切面;
 - after throwing: 在切点因为异常退出时执行切面;
 - after (finally): 无论切点以什么形式退出都会执行切面;
 - around: 切面逻辑可以主动控制方法逻辑的调用，可以在方法前后插入任意逻辑。这种方式显然最为强大，因为它甚至可以阻断正常调用，返回自己特定的 `return value`;

 > spring AOP 提供了完整的 Advice 类型，也许大家会觉得 `around` 用起来简直爽到爆了, 但是值得提醒的是权限越大责任也越大，随之而来的风险也越大了，因此尽量只选择足够功能的 Advice 类型才是王道呀。

#### @Before 通知声明:

- before 类型的 Advice 使用 @Before(pointcut expression) 来标注方法实现：

 ```
 import org.aspectj.lang.annotation.Aspect; import org.aspectj.lang.annotation.Before;
 @Aspect
 public class BeforeExample {
 // @Before("com.xyz.myapp.SystemArchitecture.dataAccessOperation()")  通过切点引用声明切入切入点
     @Before("execution(* com.xyz.myapp.dao.*.*(..))")                     // 通过切点表达式声明切入点
     public void doAccessCheck() { // ...
     }}
 ```

#### @AfterReturning 通知声明:

- 见样例:

 ```
	import org.aspectj.lang.annotation.Aspect;
    import org.aspectj.lang.annotation.AfterReturning;
    @Aspect
    public class AfterReturningExample {
    @AfterReturning("com.xyz.myapp.SystemArchitecture.dataAccessOperation()")
    public void doAccessCheck() { // ...
    } }
 ```

- 可能我们希望访问方法返回的返回值，此时可以用 returnning 指定返回值参数名称:

 ```
 import org.aspectj.lang.annotation.Aspect;
 import org.aspectj.lang.annotation.AfterReturning;
 @Aspect
 public class AfterReturningExample {
    @AfterReturning(pointcut="com.xyz.myapp.SystemArchitecture.dataAccessOperation()",
    returning="retVal")
 public void doAccessCheck(Object retVal) { // ...
 } }
 ```

#### @AfterThrowing 通知声明:

- 见样例:

 ```
	import org.aspectj.lang.annotation.Aspect; import org.aspectj.lang.annotation.AfterThrowing;
	@Aspect
	public class AfterThrowingExample {
	    @AfterThrowing("com.xyz.myapp.SystemArchitecture.dataAccessOperation()")
	public void doRecoveryActions() { // ...
	} }
 ```

- 通常可以定义指定异常类型的切点通知，且需要在执行逻辑中使用该异常对象(方法参数的异常类型可以为 `Throwable`)

 ```
	import org.aspectj.lang.annotation.Aspect; import org.aspectj.lang.annotation.AfterThrowing;
	@Aspect
	public class AfterThrowingExample {
	    @AfterThrowing(
   		     pointcut="com.xyz.myapp.SystemArchitecture.dataAccessOperation()",
       	  throwing="ex")
	public void doRecoveryActions(DataAccessException ex) { // ...
	} }
 ```

#### @After 通知声明:

- 见样例:

 ```
	import org.aspectj.lang.annotation.Aspect; import org.aspectj.lang.annotation.After;
	@Aspect
	public class AfterFinallyExample {
	    @After("com.xyz.myapp.SystemArchitecture.dataAccessOperation()")
	public void doReleaseLock() { // ...
	} }
 ```
 > after 通知通常在方法结束后运行，因此不能从通知逻辑中抛出异常。该通知通常用于释放资源

#### @Arround 通知声明:

- 见样例:

 ```
	import org.aspectj.lang.annotation.Aspect; import org.aspectj.lang.annotation.Around; import 	org.aspectj.lang.ProceedingJoinPoint;
	@Aspect
	public class AroundExample {
	    @Around("com.xyz.myapp.SystemArchitecture.businessService()")
	public Object doBasicProfiling(ProceedingJoinPoint pjp) throws Throwable { // start stopwatch
	Object retVal = pjp.proceed();
	// stop stopwatch
	return retVal; }
	}
 ```

 > `ProceedingJoinPoint` 类型参数是around通知的必须参数， pip.proceed() 可以调用被代理方法执行。因此在around通知中，被代理方法是否执行完全取决于代理逻辑。


### V. Advice 的参数管理

#### JoinPoint 参数:

- 所有的 advice 方法都可以将第一个参数定义为`org.aspectj.lang.JoinPoint`类型（around advice方法中的第一个参数类型是ProceedingJoinPoint，它是JointPoint的子类），JoinPoint 参数封装了许多包含代理对象及目标对象信息获取的方法，对于代理逻辑十分有用。

#### 其他传入参数:

- 在上面的 `After Returnning Advice` 和 `After Throwing Advice` 样例中，我们已经见到了一些外部参数传递方式。这里我们先使用 `args pointcut` 来演示如何传递外部参数:

 ```
 @Pointcut("com.xyz.myapp.SystemArchitecture.dataAccessOperation() && args(account,..)")
 private void accountDataAccessOperation(Account account) {}
 @Before("accountDataAccessOperation(account)")
 public void validateAccount(Account account) { // ...
 }
 ```
 > 上面样例中 `validateAccount` 方法的参数列表定义了 `Account account` 参数 和 `args pointcut` 定义的参数名称一致（回顾一下 `args pointcut` 定义的是运行时传入参数类型，这里只定义了参数名称），spring AOP 框架将根据 方法参数的类型来确定 args 参数限定类型，同时从符合限定的方法调用中传递参数给 advice 方法。

- 其他pointcut类型的参数传递也是类似的:

 ```
 @Retention(RetentionPolicy.RUNTIME) @Target(ElementType.METHOD)
 public @interface Auditable {
     AuditCode value();
 }
 ```

 ```
 @Before("com.xyz.lib.Pointcuts.anyPublicMethod() && @annotation(auditable)")
 public void audit(Auditable auditable) { AuditCode code = auditable.value(); // ...
 }
 ```

#### 泛型参数传递:

- spring AOP 在参数传递中也支持泛型处理，我们先定义泛型类型如下:

 ```
 public interface Sample<T> {
 void sampleGenericMethod(T param);
 void sampleGenericCollectionMethod(Collection<T> param);
 }
 ```

- 接着定义切面逻辑，因为需要传递参数，我们需要限定参数的实际类型:

 ```
 @Before("execution(* ..Sample+.sampleGenericMethod(*)) && args(param)")
 public void beforeSampleMethod(MyType param) { // Advice implementation
 }
 ```

 > 显然这种切面定义是切实可行的，但是这种参数类型限定在泛型类中可能会遇到麻烦。比如我们定义如下切面:

 ```
 @Before("execution(* ..Sample+.sampleGenericCollectionMethod(*)) && args(param)")
 public void beforeSampleMethod(Collection<MyType> param) { // Advice implementation
 }
 ```
 > 此时为了校验运行时参数， Spring AOP 将校验参数容器中每个元素的类型，但这样做并不靠谱呀，我们并不知道容器中的null对象是否属于限定的类型 ... 因此，spring AOP 使用了一种近似形式的传递形式: 将参数了类型指定为 `Collection<?>`, 将元素的类型校验交给咱们啦 ^ ^。

#### 参数名称的定义:

 也许有人已经发现，定义在Advice方法中的参数名称并不会在运行时获得的呀，那 spring AOP 是如何进行名称匹配的嘛😹！？

 不打紧，spring AOP 已经考虑到了，它提供了 三种策略 进行参数名匹配:

  1. 使用 `argNames` 参数列表:

	- 直接上代码
	
   ```
     @Before(value="com.xyz.lib.Pointcuts.anyPublicMethod() && target(bean) && @annotation(auditable)",
           argNames="bean,auditable")
   public void audit(Object bean, Auditable auditable) { AuditCode code = auditable.value();
   // ... use code and bean
   }
   ```
   > 看出端倪了吗？`argNames` 用一个逗号间隔的字符串定义了完整的参数名称列表(注意定义顺序哈~)
   >
   > 其实还有更强大的方式:

   ```
    @Before(value="com.xyz.lib.Pointcuts.anyPublicMethod() && target(bean) && @annotation(auditable)",
         argNames="bean,auditable")
       public void audit(JoinPoint jp, Object bean, Auditable auditable) { AuditCode code = auditable.value();
       // ... use code, bean, and jp
    }
   ```
   > JoinPoint 参数作为 Advice 方法的第一个参数并没有在 argNames 中显示定义其名称。是的，默认是可以省略的👊。这让我们码农方便了不少呀 ^ ^。

  2. 获取类的debug信息:

    写 argNames 总还是有些麻烦，当程序员未定义这个变量时，spring AOP 将尝试获取该类的 debug 信息。这些信息在编译后默认是不会保留的，需要显式在编译时驾驶 `-g:vars`  参数。增加这个参数会产生的结果:
    - 代码因为没有 argNames 参数会略微易读一些;
    - 编译后生成的class文件会略微大一些;
    - 编译阶段原有对未使用本地变量的优化的功能将不再执行;

   总而言之，编译时增加该标记并不会对项目有多少影响。

  3. 简单名称推断:

	- 上面两步都没做，那就只能靠spring AOP 自己去猜（推断）啦 ~
	- spring的推断只是简单依据参数个数进行匹配，例如只定义了一个参数，那还用啥名称匹配呢（^ ^）？

  4. 还不行那就抛错吧:

    - 没错, 再不行spring AOP就会抛出 `IllegalArgumentException` 异常。

#### 调用原方法时的参数传递:

- 这里无需多说，只需要按顺序创建参数列表数组并传递给 `proceed()` 方法即可:

 ```
 @Around("execution(List<Account> find*(..)) && " +
         "com.xyz.myapp.SystemArchitecture.inDataAccessLayer() && " +
         "args(accountHolderNamePattern)")
 public Object preProcessQueryPattern(ProceedingJoinPoint pjp, String accountHolderNamePattern) throws Throwable {
     String newPattern = preProcess(accountHolderNamePattern);
 return pjp.proceed(new Object[] {newPattern}); }
 ```

#### 多个Advice 在一个 join point 处的执行顺序:

- 如果在一个 join point 处有多个 advice，Spring AOP 采用和 AspectJ 类似的优先级来指定通知的执行顺序。目标函数调用前，优先级高的advice先执行，目标函数调用后，优先级高的advice后执行。

- 如果两个通知分别定义在各自的 Aspect 内，可以通过如下两种方式控制 Aspect 的施加顺序：

 1. Aspect 类添加注解指定顺序值：org.springframework.core.annotation.Order
 2. Aspect 类实现接口通过`getOrder()`方法指定顺序值：org.springframework.core.Ordered

 > 顺序值是一个整数，数值越小代表的优先级越大

- 如果两个 advice 位于同一 aspect 内，且执行顺序有先后，通过 advice 的声明顺序是无法确定其执行顺序的，因为 advice 方法的声明顺序无法通过反射获取，只能采取如下变通方式，二选一：

 1. 将两个 advice 合并为一个 advice，那么执行顺序就可以通过代码控制了
 2. 将两个 advice 分别抽离到各自的 aspect 内，然后为 aspect 指定执行顺序

#### introduction 引入功能:

 `Introduction 引入功能` 将使被代理的对象拥有额外接口，使其无需继承便拥有特定接口的特定实现。Introduction 使用 `@DeclareParents`注解定义引入的接口和实现。下面贴出样例来分析引用过程:

 ```
 @Aspect
 public class UsageTracking {

     @DeclareParents(value="com.xzy.myapp.service.*+", defaultImpl=DefaultUsageTracked.class)
     public static UsageTracked mixin;

     @Before("com.xyz.myapp.SystemArchitecture.businessService() && this(usageTracked)")
     public void recordUsage(UsageTracked usageTracked) { usageTracked.incrementUseCount();
 } }
 ```

 > 上面样例中 `UsageTracked` 是一个接口, `DefaultUsageTracked` 是该接口的一个实现类。上面定义的`@DeclareParents(value="com.xzy.myapp.service.*+", defaultImpl=DefaultUsageTracked.class)`声明了`com.xzy.myapp.service`包下的所有类都将引入`UsageTracked`接口的功能，默认执行`DefaultUsageTracked.class`类的实现逻辑。

#### spring AOP 切面装载模型:

  - 默认情况下 spring 会为每个 `切面类` 在应用上下文中创建单个实例，在 `AspectJ` 中这种方式称为 `singleton install model（单例装载模型）`。其实spring还支持`AspectJ`中的 `perthis` 和 `pertarget` 模型。下面来介绍一下spring支持的三种实例装载模型:

    1. singleton: 每个切面类在应用上下文中只会生成一个 `切面实例`,该实例会被全局复用;
    2. perthis: 对于每个代理对象，生成各自的 `切面实例`，生命周期跟随代理对象;
    3. pertarget: 对于每个目标对象, 生成各自的 `切面实例`，生命周期跟随目标对象;

    > singleton 模型在大多数场景下是非常高效的，但是当一个 `AspectJ类` 定义了状态信息，我们就要考虑使用 `perthis` 或 `pertarget` 模型了。

  - 显式声明装载模型:

  ```
  @Aspect("perthis(com.xyz.myapp.SystemArchitecture.businessService())")
  public class MyAspect { private int someState;
      @Before(com.xyz.myapp.SystemArchitecture.businessService())
  public void recordServiceUsage() { // ...
  } }
  ```

  如上所示，`perthis` 声明语法为 `perthis(Pointcut)`, 将其显式定义为 @AspectJ 的值之后便启用 perthis 装载模式了。`pertarget` 的声明和 `perthis` 类似。
  另外提一点，目前只有注解形式的 spring AOP 配置才能支持装载模型的灵活配置。


## 总结

本次只是简单了解了 AOP 的基本概念以及其使用方式，可以说除了概念较丰富之外并无过多难度。后续将进一步梳理 spring AOP 的更多内容，包括 `spring AOP API`, `spring AOP 实现原理`, `spring AOP 应用场景实践`等。欢迎各位小伙伴多提意见 ^ ^。
