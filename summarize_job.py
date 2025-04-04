import openai
import os

# API Key environment variable se lo
openai.api_key = os.getenv("OPENAI_API_KEY")

if not openai.api_key:
    raise ValueError("Error: OPENAI_API_KEY is not set. Please export it in your environment.")

def summarize_job_output(job_log_path):
    try:
        # Job output file read karo
        with open(job_log_path, "r", encoding="utf-8") as file:
            job_log = file.read()[-4000:]  # Last ke 4000 characters hi bhej rahe hain

        # Latest OpenAI API Call
        client = openai.OpenAI()
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "Summarize the following Jenkins job output in 2-3 simple sentences."},
                {"role": "user", "content": job_log}
            ]
        )

        summary = response.choices[0].message.content
        return summary

    except Exception as e:
        return f"Error summarizing job output: {str(e)}"

# File ka path specify karo
job_output_file = "/home/GRAZITTI/love.pathak/Downloads/ansible/job_output.log"

# Summary generate karo
summary_text = summarize_job_output(job_output_file)

# Console pe print karo
print("\n=== Job Summary ===\n")
print(summary_text)

# Summary ko ek nayi file me save karo
summary_file_path = "/home/GRAZITTI/love.pathak/Downloads/ansible/job_summary.log"
with open(summary_file_path, "w", encoding="utf-8") as summary_file:
    summary_file.write(summary_text)

