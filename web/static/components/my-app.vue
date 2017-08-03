<template>
  <div class="my-app">
    <ul v-for="project in projects">
      <li>{{project}}</li>
    </ul>
  </div>
</template>

<script>

export default {
  const x = 1;
  console.log(x);
  data() {
    return {
      projects: ["test", "test2"]
    };
  }
}
</script>

<style lang="sass">
  .my-app {
    margin-left: auto;
    margin-right: auto;
    width: 800px;
    h1 {
      text-align: center;
    }
  }
</style>
