<template>
  <div class="my-app">
    <ul v-for="project in projects">
      <li>{{project}}</li>
      <projectcard></projectcard>
    </ul>
  </div>
</template>

<script>

export default {
  data() {
    return {
      message: "",
      test: "test",
      projects: {}
    };
  },
  computed: {
    messages() {
      return this.$parent.messages
    }
  },
  mounted() {
    var xhr = new XMLHttpRequest();
    var element = this;
    xhr.onload = function() {
      element.projects = JSON.parse(this.response).projects;
    }
    xhr.open("GET", "http://localhost:4000/json/", false);
    xhr.send();
  },
  methods: {
    sendMessage() {
      this.$parent.channel.push("new_msg", {body: this.message })
      this.message = ''
    }
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
