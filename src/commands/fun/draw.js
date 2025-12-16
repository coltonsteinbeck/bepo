import { SlashCommandBuilder, AttachmentBuilder, EmbedBuilder } from "discord.js";
import { generateImage } from "../../utils/imageGenerator.js";

const drawCommand = {
  data: new SlashCommandBuilder()
    .setName("draw")
    .setDescription("Generate an image using AI")
    .addStringOption((option) =>
      option
        .setName("prompt")
        .setDescription("The description of the image you want to generate")
        .setRequired(true)
    )
    .addStringOption((option) =>
      option
        .setName("model")
        .setDescription("The AI model to use for generation")
        .setRequired(false)
        .addChoices(
          { name: "Grok (Default)", value: "grok" },
          { name: "Nano Banana Pro", value: "gemini" },
          { name: "GPT Image 1.5", value: "gpt-image-1.5" }
        )
    )
    .addAttachmentOption((option) =>
      option
        .setName("reference")
        .setDescription("A reference image to influence the generation (Nano Banana Pro only)")
        .setRequired(false)
    ),
  async execute(interaction) {
    // Only defer if not already deferred/replied (for retry scenarios)
    if (!interaction.deferred && !interaction.replied) {
      await interaction.deferReply();
    }

    const prompt = interaction.options.getString("prompt");
    const model = interaction.options.getString("model") || "grok";
    const reference = interaction.options.getAttachment("reference");

    try {
      // Validate reference image usage
      if (reference && model !== "gemini" && model !== "gpt-image-1.5") {
        await interaction.editReply({
          content: "⚠️ Reference images are currently only supported with the **Nano Banana Pro** and **GPT Image 1.5** models.",
        });
        return;
      }

      // Validate reference image type
      if (reference && !reference.contentType.startsWith("image/")) {
        await interaction.editReply({
          content: "⚠️ The reference file must be an image.",
        });
        return;
      }

      const result = await generateImage({
        prompt,
        provider: model,
        referenceImageUrl: reference?.url,
      });

      const attachment = new AttachmentBuilder(result.buffer, { name: "generated_image.png" });
      
      const modelColors = {
        "Nano Banana Pro": 0x4285F4,
        "GPT Image 1.5": 0x10A37F,
        "GPT Image 1": 0x10A37F,
        "Grok": 0x000000
      };

      const embed = new EmbedBuilder()
        .setTitle("🎨 Image Generated")
        .setDescription(`**Prompt:** ${prompt}`)
        .setImage("attachment://generated_image.png")
        .setFooter({ text: `Generated with ${result.modelUsed}` })
        .setColor(modelColors[result.modelUsed] || 0x000000)
        .setTimestamp();

      await interaction.editReply({
        embeds: [embed],
        files: [attachment],
      });
    } catch (error) {
      console.error("Image generation error:", error);
      
      let errorMessage = "Failed to generate image. Please try again.";
      if (error.message.includes("safety")) {
        errorMessage = "The prompt triggered safety filters. Please try a different prompt.";
      } else if (error.response?.status === 429) {
        errorMessage = "Rate limit exceeded. Please try again later.";
      } else if (error.message.includes("does not exist")) {
        errorMessage = "The selected model is not currently available. Please try a different model.";
      }

      try {
        await interaction.editReply({
          content: `❌ ${errorMessage}\n\`${error.message}\``,
        });
      } catch (replyError) {
        console.error("Failed to send error reply:", replyError.message);
      }
    }
  },
};

export default drawCommand;
