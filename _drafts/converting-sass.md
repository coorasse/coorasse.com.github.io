I want to share my learnings while moving from SCSS to CSS in a Rails project, which uses Sprockets for assets compilation.

The project uses Bootstrap as CSS Framework, importmaps, and [does not need jsbundling](https://dev.to/coorasse/rails-7-bootstrap-5-and-importmaps-without-nodejs-4g8), which makes working on the project a breeze.

I love this project setup, mainly because I don't need a second or a third process running, that watches over my assets, and compiles them in the background.

## The problem

There's still something that is not cool, when working with this setup: scss files compilation is slow. Too slow.
Working on the frontend with this setup is painful: each change you make to any SCSS file means almost a second to reload the page with the adapted styles. Although this might seem "fast enough", is definitely not fast enough when you spend an entire day, or maybe a week of work, fully on CSS.

## The plan

We decided to optimize this workflow and explore our possibilities. The plan is the following, step by step:
* convert all SCSS files to pure CSS. Isolate everything that cannot be converted.
* leave all scss files in the application.scss and include the single CSS files we extracted via importmaps.

## How to convert

We identified these cases during the process:

### nested styles

The following stay exactly as it is in CSS, so there's no need to change it:

```scss
.ribbon {
  .flag {
    width: 225px;
  }
}
```

Please note that some special cases apply. [Read more on SASS blog](https://sass-lang.com/blog/sass-and-native-nesting/). There are cases, where your usage of nested SASS styles, might be incompatible with CSS one, so you have to change your code.

### SASS variables

We have to distinguish three cases:

**your SASS variables**
You can convert these to CSS variables.

The following:

```scss
$ribbon-container-size: 150px;

.ribbon {
  width: $ribbon-container-size;
  height: $ribbon-container-size;
}
```

can be rewritten as:

```css
.ribbon {
  --ribbon-container-size: 150px;
  width: var(--ribbon-container-size);
  height: var(--ribbon-container-size);
}
```

**Bootstrap CSS variables**
Bootstrap [exposes tons of SASS variables as CSS variables](https://getbootstrap.com/docs/5.3/customize/css-variables/). The following for example:

```scss
.ribbon {
  background-color: $primary;
}
```

can be rewritten as:

```css
.ribbon {
  background-color: var(--bs-primary);
}
```

**Bootstrap SASS variables**
If you make use of a Bootstrap SASS variable that is not available as CSS variables you have two options:

1. Isolate the usage in a separate SASS file and convert the remaining to CSS.
2. Extract the variables as CSS. In the example below, I extract the SASS variable to a CSS variable.

```css
# assets/css_variables.scss
:root {
  --bs-link-decoration: $link-decoration;
}
```

```css
# assets/ribbon.css
.ribbon {
  text-decoration: var(--bs-link-decoration);
}
```

### Media queries

Unfortunately. As of today (03.02.2024) there's no way to convert this to pure CSS:

```scss
.ribbon {
  color: red;

  @include media-breakpoint-up(lg) {
    color: blue;
  }
}
```

[CSS variables cannot be used in media queries](https://getbootstrap.com/docs/5.3/customize/css-variables/#grid-breakpoints)

My suggestion here is to split it and put your media queries in the SCSS file.

## The unexpected benefit

When migrating file by file, we had an unexpected benefit at this point: we converted `_ribbon.scss` to `ribbon.css` and kept including it like before in our `application.scss` via `@import "components/_ribbon.css";` (note that the entire file name and the CSS extension must be defined now!).
Now dart-sass will not even try to compile this file anymore, and simply concatenating it. This means that even without   extracting the file, but keeping it in place, the sprockets cache mechanism helps us a lot, and does not require to re-compile each scss file. This means that every change to our CSS files, even if included in a SASS file and in the build pipeline, don't need to be recompiled, and our changes are immediate! In a rather small project, we are talking about a difference from 800ms to 20ms, so it's as if it did not need to be recompiled at all.

